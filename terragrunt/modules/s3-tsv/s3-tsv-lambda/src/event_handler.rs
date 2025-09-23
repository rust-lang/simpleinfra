use aws_config::BehaviorVersion;
use aws_sdk_s3::Client;
use lambda_runtime::{tracing::info, Error, LambdaEvent};
use serde::Deserialize;

#[derive(Debug, Clone)]
pub struct S3Object {
    pub key: String,
    pub etag: String,
}

/// Generate TSV content from S3 objects for Google Cloud Storage Transfer
pub fn generate_tsv(bucket: &str, objects: &[S3Object]) -> String {
    let mut tsv = String::from("TsvHttpData-1.0\n");

    for object in objects {
        let url = format!("https://{}.s3.amazonaws.com/{}", bucket, object.key);
        let etag = object.etag.trim_matches('"');
        tsv.push_str(&format!("{}\t{}\n", url, etag));
    }

    tsv
}

#[derive(Debug, Deserialize)]
pub struct EventPayload {
    pub bucket: String,
}

pub(crate) async fn function_handler(event: LambdaEvent<EventPayload>) -> Result<(), Error> {
    let payload = event.payload;
    let bucket = payload.bucket.as_str();

    info!(payload=?payload, bucket, "Received event");

    // Initialize AWS S3 client
    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;
    let client = Client::new(&config);

    // List objects in the bucket (limited to first 3)
    let response = client
        .list_objects_v2()
        .bucket(bucket)
        .max_keys(3)
        .send()
        .await?;

    if let Some(objects) = response.contents {
        if objects.is_empty() {
            return Err(Error::from(format!(
                "No objects found in bucket '{bucket}'"
            )));
        }

        // Convert AWS S3 objects to our internal format
        let s3_objects: Vec<S3Object> = objects
            .iter()
            .map(|obj| S3Object {
                key: obj.key().unwrap_or("<no key>").to_string(),
                etag: obj.e_tag().unwrap_or("").to_string(),
            })
            .collect();

        // Generate and print TSV content
        let tsv_content = generate_tsv(bucket, &s3_objects);
        print!("{}", tsv_content);
    } else {
        return Err(Error::from(format!(
            "No objects found in bucket '{bucket}'"
        )));
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lambda_runtime::{Context, LambdaEvent};

    #[tokio::test]
    #[ignore = "requires AWS to run"]
    async fn test_event_handler() {
        let e = EventPayload {
            bucket: "staging-crates-io".to_string(),
        };
        let event = LambdaEvent::new(e, Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!((), response);
    }

    #[test]
    fn test_generate_tsv_empty_objects() {
        let bucket = "test-bucket";
        let objects = vec![];

        let tsv = generate_tsv(bucket, &objects);

        assert_eq!(
            tsv,
            "TsvHttpData-1.0
"
        );
    }

    #[test]
    fn test_generate_tsv_single_object() {
        let bucket = "staging-crates-io";
        let objects = vec![S3Object {
            key: "path/to/file.txt".to_string(),
            etag: "\"abc123def456\"".to_string(),
        }];

        let tsv = generate_tsv(bucket, &objects);

        let expected = "TsvHttpData-1.0
https://staging-crates-io.s3.amazonaws.com/path/to/file.txt\tabc123def456
";
        assert_eq!(tsv, expected);
    }

    #[test]
    fn test_generate_tsv_multiple_objects() {
        let bucket = "staging-crates-io";
        let objects = vec![
            S3Object {
                key: "file1.txt".to_string(),
                etag: "\"etag1\"".to_string(),
            },
            S3Object {
                key: "dir/file2.pdf".to_string(),
                etag: "\"etag2\"".to_string(),
            },
            S3Object {
                key: "images/photo.png".to_string(),
                etag: "\"etag3\"".to_string(),
            },
        ];

        let tsv = generate_tsv(bucket, &objects);

        let expected = "TsvHttpData-1.0
https://staging-crates-io.s3.amazonaws.com/file1.txt\tetag1
https://staging-crates-io.s3.amazonaws.com/dir/file2.pdf\tetag2
https://staging-crates-io.s3.amazonaws.com/images/photo.png\tetag3
";

        assert_eq!(tsv, expected);
    }

    #[test]
    fn test_generate_tsv_etag_quote_handling() {
        let bucket = "test-bucket";
        let objects = vec![
            S3Object {
                key: "quoted.txt".to_string(),
                etag: "\"abc123\"".to_string(), // With quotes
            },
            S3Object {
                key: "unquoted.txt".to_string(),
                etag: "def456".to_string(), // Without quotes
            },
        ];

        let tsv = generate_tsv(bucket, &objects);

        let expected = "TsvHttpData-1.0
https://test-bucket.s3.amazonaws.com/quoted.txt\tabc123
https://test-bucket.s3.amazonaws.com/unquoted.txt\tdef456
";

        assert_eq!(tsv, expected);
    }

    #[test]
    fn test_generate_tsv_special_characters_in_key() {
        let bucket = "test-bucket";
        let objects = vec![S3Object {
            key: "path/with spaces/file-name_123.txt".to_string(),
            etag: "\"special123\"".to_string(),
        }];

        let tsv = generate_tsv(bucket, &objects);

        let expected = "TsvHttpData-1.0
https://test-bucket.s3.amazonaws.com/path/with spaces/file-name_123.txt	special123
";
        assert_eq!(tsv, expected);
    }

    #[test]
    fn test_tsv_format_compliance() {
        // Test that the format matches Google Cloud Storage Transfer requirements
        let bucket = "staging-crates-io";
        let objects = vec![
            S3Object {
                key: "myfile.pdf".to_string(),
                etag: "\"wHENa08V36iPYAsOa2JAdw==\"".to_string(),
            },
            S3Object {
                key: "images/dataset1/flower.png".to_string(),
                etag: "\"R9acAaveoPd2y8nniLUYbw==\"".to_string(),
            },
        ];

        let tsv = generate_tsv(bucket, &objects);

        let expected = "TsvHttpData-1.0
https://staging-crates-io.s3.amazonaws.com/myfile.pdf\twHENa08V36iPYAsOa2JAdw==
https://staging-crates-io.s3.amazonaws.com/images/dataset1/flower.png\tR9acAaveoPd2y8nniLUYbw==
";

        assert_eq!(tsv, expected);
    }
}
