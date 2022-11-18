data "aws_ssoadmin_instances" "rust" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.rust.identity_store_ids[0]
  instance_arn      = data.aws_ssoadmin_instances.rust.arns[0]
}

resource "aws_identitystore_group" "infra-admins" {
  identity_store_id = local.identity_store_id

  display_name = "infra-admins"
  description  = "The administrators of the Rust organization"
}

resource "aws_identitystore_group" "infra" {
  identity_store_id = local.identity_store_id

  display_name = "infra"
  description  = "The infrastructure team"
}

resource "aws_ssoadmin_permission_set" "administrator_access" {
  instance_arn = local.instance_arn
  name         = "AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}

resource "aws_ssoadmin_permission_set" "view_only_access" {
  instance_arn = local.instance_arn
  name         = "ViewOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "view_only_access" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.view_only_access.arn
}
