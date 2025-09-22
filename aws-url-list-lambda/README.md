# aws-url-list-lambda

AWS Lambda (Rust) that lists S3 bucket contents and returns a TSV string compatible with Google Storage Transfer Service URL list format (TsvHttpData-1.0).

Input event JSON:

{
  "bucket": "dev-static-rust-lang-org",
  "prefix": null,
  "base_url": "https://dev-static.rust-lang.org"
}

- bucket: required S3 bucket name
- prefix: optional key prefix to limit listing
- base_url: optional HTTP/HTTPS base used to construct URLs; if omitted, defaults to https://{bucket}.s3.amazonaws.com/{key} and percent-encodes the key

Output: the TSV content as a string.

Testing: unit tests cover TSV generation and sorting. For integration tests against S3, consider using Localstack or MinIO.
