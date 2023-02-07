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

The [Terragrunt] configuration is split into two parts: _modules_ and _state_:

- _Modules_ are normal [Terraform] modules that each define a specific part of
  our infrastructure. They are stored in the [`modules`](#modules) directory.
- _State_ represents concrete instances of our infrastructure. For example, the
  [staging environment for `crates.io`](./accounts/legacy/crates-io-staging) is
  an instances of the [`crates-io`](./modules/crates-io) [Terraform] module.
  State is managed using [Terragrunt], and is configured inside the
  [`accounts`](#accounts) directory.

Both concepts are described in more details below.

### `accounts`

The `accounts` subdirectory contains the _state_ of our infrastructure.

A _state_ is a concrete instance of a _service_ or a shared module, which has
been defined as a [Terraform] module in [`modules`](#modules). States are
deployed using [Terragrunt], and are grouped by the account in which they run.

Given the following directory structure:

```text
accounts
└── dev-desktops-prod
    ├── westeurope
    └── westus2
```

`dev-desktops-prod` is the (AWS) _account_ that stores the Terraform state files
for this environment. `westeurope` and `westus2` are two _states_, i.e. concrete
instances of the [`dev-desktops-azure`](./modules/dev-desktops-azure) module.
While these modules are deployed to Azure, their state is stored inside the
parent AWS account.

### `modules`

The `modules` subdirectory contains the _configuration_ for our infrastructure.
We use [Terraform] to declare our infrastructure as code, which we have split
into composable _modules_.

Modules at the root of the `modules` directory are called _services_ and define
an app or service within our infrastructure. For example, we have a module for
our [dev desktops](./modules/dev-desktops-azure) that contains every piece of 
infrastructure that is required to run one or more instances on Azure.

_Services_ can be deployed multiple times. Each deployment is a concrete
instance of the configuration, and is managed with [Terragrunt] as a _state_
inside the [`accounts`](#accounts) directory. For example, `crates.io` has a
staging and a production _state_, which are both configured through the
[`crates-io`](./modules/crates-io) _service_ module.

Modules that are generic and can be shared between _services_ are stored in the
`modules/shared` directory. They often provide a higher-level abstraction over
concrete implementation details. For example, the shared module
[`acm-certificate`](modules/acm-certificate) makes it easy to generate
a TLS certificate for a list of domain names.

## State vs. Module

We have two tools to define dependencies between pieces of our infrastructure:

  1. With [Terragrunt], we can define [dependencies](https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#dependencies-between-modules)
     between [_states_](#accounts). 
  2. A [Terraform] module can include other modules.

### State

As a rule of thumb, we want to use dependencies in [Terragrunt] to _share
resources within an account_. For example, we can create an ECS cluster in an
account and run multiple services on it. The cluster and each service would be
configured with its own _state_:

```text
accounts
└── docs-rs-staging
    ├── docs-rs-web
    ├── docs-rs-worker
    └── ecs-cluster
```

In this example, `docs-rs-web` and `docs-rs-worker` both have a dependency on
the `ecs-cluster`.

### Module

On the other hand, we want to use [Terraform] modules for anything that can be
reused and shared inside _services_. These resources are scoped to each _state_
or _service_, but are not shared across an _account_.

For example, the [`acm-certificate`](modules/acm-certificate) module
creates TLS certificates. When included in a service such as `crates-io`, each
instance of the service will create its own certificate.

## Running Terragrunt

When running [Terragrunt], it fetches and stores the state of the infrastructure
in AWS. This requires that an AWS profile is configured for each account. After
that has been done, running [Terragrunt] is as simple as replacing `terraform`
with `terragrunt` in the command.

### Configure AWS Profiles

Running [Terragrunt] requires permissions to the AWS account you are
configuring. For each of the accounts, copy the following snippet into the
configuration file at `~/.aws/config`:

```text
[profile rust-root]
sso_start_url = https://rust-lang.awsapps.com/start
sso_account_id = <rust-root-account-id>
sso_role_name = AdministratorAccess
sso_region = us-east-1
region = us-east-1
```

Each account in `./accounts` has a `account.json` file that contains the name of
the respective profile. In the above example, `./account/root/account.json` sets
the profile name to `rust-root`.

The `sso_account_id` can be found in the web interface of AWS SSO. Open the
`sso_start_url` in a browser, log in, and you'll see a list of accounts with
their respective account ids.

### Run Terragrunt

Before running Terragrunt, make sure you are signed into the correct AWS
profile. For example, run the following command to sign into the `rust-root`
account:

```shell
aws sso login --profile rust-root
```

You can then `cd` into the corresponding service within the `accounts` directory
and run `terragrunt plan` to see the plan terraform will apply and
`terragrunt apply` to actually apply the plan.

[terraform]: https://www.terraform.io/
[terragrunt]: https://terragrunt.gruntwork.io/
