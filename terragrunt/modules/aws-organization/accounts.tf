resource "aws_organizations_organization" "rust" {
  aws_service_access_principals = ["sso.amazonaws.com"]
}

resource "aws_organizations_account" "admin" {
  name  = "rust-root"
  email = "admin+root@rust-lang.org"
}

resource "aws_organizations_account" "legacy" {
  name  = "Rust Admin - 8450"
  email = "admin@rust-lang.org"
}

resource "aws_organizations_account" "crates_io_staging" {
  name  = "crates-io-staging"
  email = "admin+crates-io-staging@rust-lang.org"
}

resource "aws_organizations_account" "crates_io_prod" {
  name  = "crates-io-prod"
  email = "admin+crates-io-prod@rust-lang.org"
}

resource "aws_organizations_account" "docs_rs_staging" {
  name  = "docs-rs-staging"
  email = "admin+docs-rs-staging@rust-lang.org"
}

resource "aws_organizations_account" "dev_desktops_prod" {
  name  = "dev-desktops-prod"
  email = "admin+dev-desktops-prod@rust-lang.org"
}

resource "aws_organizations_account" "bors_staging" {
  name  = "bors-staging"
  email = "admin+bors-staging@rust-lang.org"
}

resource "aws_organizations_account" "bors_prod" {
  name  = "bors-prod"
  email = "admin+bors-prod@rust-lang.org"
}
