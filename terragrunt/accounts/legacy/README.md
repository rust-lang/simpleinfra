# Legacy

This account represents the AWS root account that was used before we set up a
new AWS organization with SSO[^1]. The resources in the account were previously
managed by Terraform, and have been migrated here one-by-one to separate their
respective staging and production environments.

This terragrunt configuration is an interim solution until we can set up
individual AWS accounts for each environment and migrate the resources.

[^1]: https://github.com/rust-lang/simpleinfra/pull/154
