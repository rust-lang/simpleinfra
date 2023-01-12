# Bastion server configuration

This directory contains the Terraform configuration to deploy the bastion
server inside a VPC.

## Configuration overview

### `firewall.tf`

Configuration for the security group protecting our bastion server. If you want
to tweak who can connect to the bastion this is the place to look into!

### `instance.tf`

Creation of the bastion's EC2 instance. If you need to tweak the instance specs
this is the place to look for!
