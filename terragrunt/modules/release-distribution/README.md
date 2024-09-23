# Release distribution

This module creates the infrastructure that distributes Rust releases.

Rust releases are distributed through the AWS S3 bucket `static-rust-lang-org`.
This bucket is served at `static.rust-lang.org` by CloudFront and Fastly CDNs.

The terraform variables `static_cloudfront_weight` and `static_fastly_weight` control the
distribution of traffic between CloudFront and Fastly.

If you want to use a specific CDN, use `fastly-static.rust-lang.org` or `cloudfront-static.rust-lang.org`.

The Fastly CDN is configured via the VCL language, while the CloudFront CDN is configured via Javascript AWS lambda functions.

## Lambdas

The following lambdas manage requests starting with the following URLs:

- [doc-router](./lambdas/doc-router/index.js):
  - dev: dev-doc.rust-lang.org
  - prod: doc.rust-lang.org
- [static-router](./lambdas/static-router/index.js):
  - dev: dev-static.rust-lang.org
  - prod: static.rust-lang.org
