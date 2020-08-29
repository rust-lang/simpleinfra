# Terraform configuration

This directory contains the Terraform configuraton used to deploy and maintain
the cloud resources managed by the Rust Infrastructure Team. Currently this
only manages a subset of our AWS usage, but its coverage is expected to grow
over time.

## Applying the configuration

To apply the configuration you'll need to have [Terraform 0.13
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

In our configuration, the state is stored in the `rust-terraform` S3 bucket
(`simpleinfra.tfstate` file), and to prevent concurrent changes to that state
the `terraform-state-lock` DynamoDB table (in the `us-west-1` region) is used.

## Resources

* [Terraform documentation][tf-docs]
* [AWS Terraform provider][tf-aws-provider]

[tf-install]: https://www.terraform.io/downloads.html
[tf-docs]: https://www.terraform.io/docs/cli-index.html
[tf-aws-provider]: https://www.terraform.io/docs/providers/aws/index.html
