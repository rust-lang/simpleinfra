resource "aws_organizations_organization" "rust" {
  aws_service_access_principals = ["sso.amazonaws.com"]
}

resource "aws_organizations_account" "admin" {
  name  = "rust-root"
  email = "admin+root@rust-lang.org"
}
