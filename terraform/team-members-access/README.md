# Team members access

This directory contains the Terraform configuration for granting members of a
Rust team access to our AWS resources.

* [How to interact with our Terraform configuration](../README.md)
* [Documentation on managing AWS access][forge]

[forge]: https://forge.rust-lang.org/infra/docs/aws-access-management.html

## Configuration overview

### `<TEAM_NAME>.tf`

Each Rust team has its own dedicated configuration file, containing the
resources to create the group and to assign the necessary policies. This is the
place to look for if you need to change the set of permissions a team has.

### `_users.tf`

Definition of all the IAM users on our AWS account, and the groups they belong
to. This is the place to look for if you need to add or remove users.

### `_shared.tf`

Policies shared between multiple teams, such as enforcing MFA or granting
access to manage a user's own credentials. This is the place to look for if a
policy you want to change was not defined inline in the team's configuration
file.

### `_terraform.tf`

Terraform boilerplate.
