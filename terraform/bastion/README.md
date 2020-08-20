# Bastion server configuration

This directory contains the Terraform configuration to deploy the bastion
server on the us-west-1 AWS region, inside our main production VPC.

* [Bastion configuration on the forge][docs]

[docs]: https://forge.rust-lang.org/infra/docs/bastion.html

## Configuration overview

### `firewall.tf`

Configuration for the security group protecting our bastion server. If you want
to tweak who can connect to the bastion this is the place to look into!

### `instance.tf`

Creation of the bastion's EC2 instance. If you need to tweak the instance specs
this is the place to look for!

### `_terraform.tf`

Terraform boilerplate.
