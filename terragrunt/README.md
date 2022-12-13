# Terragrunt

This directory contains all the infrastructure configuration controlled through
Terragrunt.

## What and why Terragrunt?

[Terragrunt] is a wrapper around [Terraform] that adds some additional
functionality that we find useful. The features of Terragrunt we use are:

  - [Managed state files](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/#keep-your-backend-configuration-dry):
    Terragrunt can create the S3 bucket and DynamoDB tables that Terraform needs
    to store its state. Automating their creation ensures consistency across
    environments.
  - [Versioned environments](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/#promote-immutable-versioned-terraform-modules-across-environments):
    With Terragrunt, we can have multiple environments that use different
    versions of a Terraform module. This enables us to test on staging, review
    changes, and then update production to the specific version.

## Directory Structure

The `terragrunt` directory is split into two subdirectories.

### `accounts`

AWS account definitions which use the modules in the `modules` directory to
configure the various AWS accounts we manage.

### `modules`

The reuseable module definitions for the logical services we manage.

## Running Terragrunt

Running [Terragrunt] requires permissions to the AWS account you are
configuring. Assuming you have permission, you can `cd` into the corresponding
service within the `accounts` directory and run `terragrunt plan` to see the
plan terraform will apply and `terragrunt apply` to actually apply the plan.

[terraform]: https://www.terraform.io/
[terragrunt]: https://terragrunt.gruntwork.io/
