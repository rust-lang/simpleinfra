# Team synchronization infrastructure

This directory contains the Terraform configuration for the tooling
synchronizing team membership between the [team repo] and all the third-party
services we use. The source code of the tool lives in the [rust-lang/sync-team]
repository.

To deploy this Terraform configuration you'll need a GitHub API token with
admin access to `rust-lang/team` and `rust-lang/sync-team`, in addition to the
AWS credentials used for other modules.

[team repo]: https://github.com/rust-lang/team
[rust-lang/sync-team]: https://github.com/rust-lang/sync-team
