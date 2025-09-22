use aws_sdk_s3::{primitives::ByteStream, types::Object, Client as S3Client};
use serde::Deserialize;
use std::fmt::Write as _;
use thiserror::Error;
use tracing::info;

#[derive(Debug, Error)]
pub enum Error {
    #[error("AWS SDK error: {0}")]
    Sdk(#[source] Box<dyn std::error::Error + Send + Sync>),
    #[error("UTF-8 error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),
}

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Clone, Deserialize)]
pub struct JobInput {
    pub bucket: String,
    /// Optional prefix to filter objects in the bucket.
    pub prefix: Option<String>,
    /// Optional HTTP base URL to use for each object. If omitted, the AWS S3 HTTPS URL will be built.
    /// Example: https://dev-static.rust-lang.org
    pub base_url: Option<String>,
    /// Optional S3 bucket to upload the generated TSV into. Defaults to `bucket` if not provided.
    pub output_bucket: Option<String>,
    /// Optional S3 key for the generated TSV. If provided, the lambda will upload the TSV to S3.
    pub output_key: Option<String>,
}

/// Build a public HTTPS URL for an S3 object.
fn object_url(bucket: &str, key: &str, base_url: &Option<String>) -> String {
    fn encode_path_preserving_slashes(inp: &str) -> String {
        urlencoding::encode(inp).replace("%2F", "/")
    }
    if let Some(base) = base_url {
        // Ensure no double slashes
        let base = base.trim_end_matches('/');
        let key = key.trim_start_matches('/');
        format!("{}/{}", base, encode_path_preserving_slashes(key))
    } else {
        // Default to virtual-hosted–style URL
        // https://{bucket}.s3.amazonaws.com/{key}
        format!(
            "https://{}.s3.amazonaws.com/{}",
            bucket,
            encode_path_preserving_slashes(key)
        )
    }
}

/// Generate TSV content according to Google Storage Transfer TSV spec.
/// - First line: TsvHttpData-1.0
/// - Then rows sorted lexicographically by URL (UTF-8), tab-separated: URL [size] [md5]
pub fn generate_tsv_from_objects(
    bucket: &str,
    objects: Vec<Object>,
    base_url: Option<String>,
) -> String {
    let mut rows: Vec<(String, Option<i64>)> = objects
        .into_iter()
        .filter_map(|o| {
            let key = o.key()?;
            let size = o.size();
            Some((object_url(bucket, &key, &base_url), size))
        })
        .collect();

    rows.sort_by(|a, b| a.0.cmp(&b.0));

    let mut out = String::new();
    out.push_str("TsvHttpData-1.0\n");
    for (url, size) in rows {
        match size {
            Some(sz) if sz >= 0 => {
                let _ = writeln!(&mut out, "{}\t{}", url, sz);
            }
            _ => {
                let _ = writeln!(&mut out, "{}", url);
            }
        }
    }
    out
}

/// List objects from an S3 bucket (optionally by prefix) and generate the TSV content.
pub async fn generate_tsv_from_bucket(s3: &S3Client, mut input: JobInput) -> Result<String> {
    let mut all_objects: Vec<Object> = Vec::new();
    let mut continuation: Option<String> = None;
    loop {
        let resp = s3
            .list_objects_v2()
            .bucket(&input.bucket)
            .set_prefix(input.prefix.clone())
            .set_continuation_token(continuation.clone())
            .send()
            .await
            .map_err(|e| Error::Sdk(Box::new(e)))?;

        if let Some(contents) = resp.contents {
            all_objects.extend(contents);
        }

        let is_truncated = resp.is_truncated.unwrap_or(false);
        if is_truncated {
            continuation = resp.next_continuation_token;
        } else {
            break;
        }
    }

    info!(bucket = %input.bucket, count = all_objects.len(), "Fetched objects from bucket");

    let tsv = generate_tsv_from_objects(&input.bucket, all_objects, input.base_url.clone());

    if let Some(key) = input.output_key.take() {
        let out_bucket = input.output_bucket.unwrap_or_else(|| input.bucket.clone());
        s3.put_object()
            .bucket(&out_bucket)
            .key(&key)
            .body(ByteStream::from(tsv.clone().into_bytes()))
            .send()
            .await
            .map_err(|e| Error::Sdk(Box::new(e)))?;
        Ok(format!("s3://{}/{}", out_bucket, key))
    } else {
        Ok(tsv)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn obj(key: &str, size: i64) -> Object {
        Object::builder().key(key).size(size).build()
    }

    #[test]
    fn tsv_generation_sorts_and_includes_size() {
        let bucket = "example-bucket";
        let objects = vec![obj("b.txt", 5), obj("a.txt", 10), obj("nested/file.bin", 0)];
        let tsv = generate_tsv_from_objects(bucket, objects, None);
        let lines: Vec<_> = tsv.lines().collect();
        assert_eq!(lines[0], "TsvHttpData-1.0");
        assert_eq!(
            lines[1],
            "https://example-bucket.s3.amazonaws.com/a.txt\t10"
        );
        assert_eq!(lines[2], "https://example-bucket.s3.amazonaws.com/b.txt\t5");
        assert_eq!(
            lines[3],
            "https://example-bucket.s3.amazonaws.com/nested/file.bin\t0"
        );
    }

    #[test]
    fn base_url_override() {
        let bucket = "dev-static-rust-lang-org";
        let objects = vec![obj("path/with space.txt", 12)];
        let tsv = generate_tsv_from_objects(
            bucket,
            objects,
            Some("https://dev-static.rust-lang.org".into()),
        );
        let lines: Vec<_> = tsv.lines().collect();
        assert_eq!(lines[0], "TsvHttpData-1.0");
        // Keys are percent-encoded in URLs even with base_url
        assert_eq!(
            lines[1],
            "https://dev-static.rust-lang.org/path/with%20space.txt\t12"
        );
    }
}
