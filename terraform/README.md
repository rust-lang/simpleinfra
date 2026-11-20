# Terraform configuration

This directory contains the Terraform configuraton used to deploy and maintain
the cloud resources managed by the Rust Infrastructure Team. Currently this
only manages a subset of our AWS usage, but its coverage is expected to grow
over time.

## Applying the configuration

To apply the configuration you'll need to have [Terraform 1.10+
installed][tf-install] and AWS credentials configured on the local machine.
The first time you apply the configuration (or every time you add a new module)
you'll need to initialize Terraform locally:

```
terraform init
```

Then you can either do a dry run of the changes to see what would happen
without actually changing anything...

```
terraform plan
```

...or apply the changes in production:

```
terraform apply
```

The `apply` subcommand will still show the planned changes before running and
will prompt you for confirmation, to avoid unwanted actions being performed.
**Never run** `terraform destroy`, as that will kill our production
environment.

## Terraform state

In order to work Terraform needs to keep some state stored, which contains (for
example) the mapping between Terraform resources and the actual resources on
our cloud providers. The state needs to be synchronized between all the people
able to apply changes.

For S3-backed modules, the state is stored in the `rust-terraform` S3 bucket
in the `us-west-1` region, using a separate state key under `simpleinfra/`
for each module. S3 lockfiles (`<key>.tflock`) prevent concurrent changes to
that state. The GCS-backed modules use their configured GCS buckets and native
state locking.

## Accounts

The [`accounts`](accounts) directory contains the configuration of the AWS
accounts that have been migrated from [Terragrunt](../terragrunt/README.md). It
is organized as `accounts/<account>/<name>`, for example
`accounts/bors-staging/app`. Each of those directories is a root module:
`_terraform.tf` configures the state backend and the AWS provider, and `main.tf`
calls a module from [`terragrunt/modules`](../terragrunt/modules).

Unlike the other modules in this directory, their state is stored in the account
itself: in the `terraform-state-<account id>` S3 bucket in the `us-east-1`
region, under the key `<name>.tfstate`. Follow the same convention when adding a
root module to an account.

The AWS profile is named after the account and is set in `_terraform.tf`.
[Configure it](../terragrunt/README.md#configure-aws-profiles), then apply the
configuration from the directory:

```shell
aws sso login --profile bors-staging
cd accounts/bors-staging/app
terraform init
terraform plan
```

## Resources

* [Terraform documentation][tf-docs]
* [AWS Terraform provider][tf-aws-provider]

[tf-install]: https://www.terraform.io/downloads
[tf-docs]: https://www.terraform.io/docs/cli-index.html
[tf-aws-provider]: https://www.terraform.io/docs/providers/aws/index.html
