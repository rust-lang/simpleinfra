# s3-tsv Lambda module

This Terraform module builds and deploys the Rust-based Lambda function located in `s3-tsv-lambda`.

## Build the artifact

Important: make sure `CARGO_TARGET_DIR` is not set to a custom directory, as that would break the expected output path.

```
cargo lambda build --release --arm64
```
