//! AWS Signature Version 4 for S3 requests without a body or query string

use aws_credential_types::Credentials;
use aws_sigv4::http_request::{
    sign, PayloadChecksumKind, PercentEncodingMode, SignableBody, SignableRequest, SigningSettings,
    UriPathNormalizationMode,
};
use aws_sigv4::sign::v4::SigningParams;
use fastly::Error;
use std::time::SystemTime;

/// Compute the headers that authenticate a request to S3
///
/// `path` must be sent to S3 unchanged, including its percent-encoding.
pub fn sign_s3_request(
    method: &str,
    host: &str,
    path: &str,
    region: &str,
    credentials: Credentials,
    time: SystemTime,
) -> Result<Vec<(String, String)>, Error> {
    // S3 deviates from the generic SigV4 rules: it encodes paths only once, does not normalize
    // them, and requires the `x-amz-content-sha256` header. The AWS SDK for Rust applies the same
    // exceptions to S3:
    // https://github.com/smithy-lang/smithy-rs/blob/release-2026-10-29/aws/codegen-aws-sdk/src/main/kotlin/software/amazon/smithy/rustsdk/SigV4AuthDecorator.kt#L296-L313
    let mut settings = SigningSettings::default();
    settings.payload_checksum_kind = PayloadChecksumKind::XAmzSha256;
    settings.percent_encoding_mode = PercentEncodingMode::Single;
    settings.uri_path_normalization_mode = UriPathNormalizationMode::Disabled;

    let identity = credentials.into();
    let params = SigningParams::builder()
        .identity(&identity)
        .region(region)
        .name("s3")
        .time(time)
        .settings(settings)
        .build()?
        .into();

    let url = format!("https://{host}{path}");
    let request = SignableRequest::new(method, url, std::iter::empty(), SignableBody::Bytes(&[]))?;
    let (instructions, _signature) = sign(request, &params)?.into_parts();

    let headers = instructions.headers();
    Ok(headers
        .map(|(name, value)| (name.into(), value.into()))
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{Duration, UNIX_EPOCH};

    #[test]
    fn test_sign_s3_request() {
        fn authorization(method: &str, host: &str, path: &str, region: &str) -> String {
            let secret = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY";
            let credentials = Credentials::new("AKIDEXAMPLE", secret, None, None, "test");
            let time = UNIX_EPOCH + Duration::from_secs(1440938160); // 2015-08-30T12:36:00Z

            let headers = sign_s3_request(method, host, path, region, credentials, time).unwrap();
            let (_, authorization) = headers
                .into_iter()
                .find(|(name, _)| name == "authorization")
                .unwrap();
            authorization
        }

        let primary = "crates-io.s3.us-west-1.amazonaws.com";
        let path = "/crates/serde/serde-1.0.0.crate";
        let expected = "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-west-1/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=f5b3aceeb1b82b276d74bd503c5705e3cab54a020b5c3d73b8aaccc91370c286";
        assert_eq!(authorization("GET", primary, path, "us-west-1"), expected);

        let fallback = "crates-io-fallback.s3.eu-west-1.amazonaws.com";
        let path = "/crates/serde/serde-1.0.0-alpha.1%2Bfoo.crate";
        let expected = "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/eu-west-1/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=ef43c349ab6c9384e9f7d8157c3aa3fab9a712ca91b58c40e9ffb147285e167a";
        assert_eq!(authorization("HEAD", fallback, path, "eu-west-1"), expected);
    }
}
