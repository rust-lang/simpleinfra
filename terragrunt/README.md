# Terragrunt

This directory contains all of the infrastructure configuration controlled through terragrunt.

## What and why terragrunt?

[Terragrunt](https://terragrunt.gruntwork.io/) is a wrapper around terraform that adds some additional functionality that we find useful. The features of terragrunt we use are:
* Configuration of s3 and dynamodb to handle remote terraform state files. This is done automatically instead of needing to be configured manually as is the case when using plain terraform.
* Module reuse. Terragrunt allows for different environments (e.g., staging and production) which share almost all of their configuration. When using plain terraform this would require copy/pasting configuration and updating configuration in multiple places.


## Directory structure

The `terragrunt` directory is split into two subdirectories:
* `modules`: the reuseable module definitions for the logical services we manage.
* `aws`: AWS account definitions which use the modules in the `modules` directory to configure the various AWS accounts we manage.

## Running

Running terragrunt requires permissions to the AWS account you are configuring. Assuming you have permission, you can cd into the corresponding service within the `aws` directory and run `terragrunt plan` to see the plan terraform will apply and `terragrunt apply` to actually apply the plan.
