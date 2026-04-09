# Google Workspace

This Terraform project defines resources that enable Google Workspace
account management from [rust-lang/team](https://github.com/rust-lang/team/).

## Requirements

- [gcloud](https://cloud.google.com/cli)
- `terraform`

## Managing resources

- authenticate with `gcloud` using your `rust-lang.org` Google Workspace account

```bash
gcloud auth application-default login
```

- run `terraform` as usual

```bash
terraform init
terraform plan
```

## Additional details

Resources are scoped to one particular GCP project (`rustlang-gws-iac`),
which also hosts the Terraform state.
