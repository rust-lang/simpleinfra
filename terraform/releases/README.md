# Releases

This module creates the infrastructure that publishes Rust releases.

Releases are produced using the
[promote-release](https://github.com/rust-lang/promote-release)
tool, which runs on AWS CodeBuild.
Releases are stored in the AWS S3 bucket `static-rust-lang-org`.

The `start-release` lambda allows the release team to trigger `promote-release` to start the release process.

This module also manages the GPG keys used to sign releases.
The keys are stored in the encrypted AWS bucket `rust-release-keys`.
