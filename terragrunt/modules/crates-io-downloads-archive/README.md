# Archived Download Statistics for crates.io

This module creates the infrastructure that is used to archive download
statistics from [crates.io] for longer than 90 days. Currently, that is a single
S3 bucket that stores CSV files with daily download counts. A new bucket has
been created for this purpose, as the existing buckets for [crates.io] are
publicly accessible.

See [rust-lang/crates.io#3479] for details.

[crates.io]: https://crates.io
[rust-lang/crates.io#3479]: https://github.com/rust-lang/crates.io/issues/3479
