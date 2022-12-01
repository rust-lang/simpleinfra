data "aws_ssoadmin_instances" "rust" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.rust.identity_store_ids[0]
  instance_arn      = data.aws_ssoadmin_instances.rust.arns[0]
}

# The various user groups

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

# The different permission sets a group may have assigned to it

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

# The assignment of groups to accounts with their respective permission sets

locals {
  assignments = [
    # Admin
    {
      account : aws_organizations_account.admin,
      group : aws_identitystore_group.infra-admins,
      permissions : [aws_ssoadmin_permission_set.view_only_access, aws_ssoadmin_permission_set.administrator_access]
    },
    {
      account : aws_organizations_account.admin,
      group : aws_identitystore_group.infra,
      permissions : [aws_ssoadmin_permission_set.view_only_access]
    },
    # docs-rs Staging
    {
      account : aws_organizations_account.docs_rs_staging,
      group : aws_identitystore_group.infra-admins,
      permissions : [aws_ssoadmin_permission_set.view_only_access, aws_ssoadmin_permission_set.administrator_access]
    },
    {
      account : aws_organizations_account.docs_rs_staging,
      group : aws_identitystore_group.infra,
      permissions : [aws_ssoadmin_permission_set.view_only_access, aws_ssoadmin_permission_set.administrator_access]
    },
    # Dev-Desktops Prod
    {
      account : aws_organizations_account.dev_desktops_prod,
      group : aws_identitystore_group.infra-admins,
      permissions : [aws_ssoadmin_permission_set.view_only_access, aws_ssoadmin_permission_set.administrator_access]
    },
    {
      account : aws_organizations_account.dev_desktops_prod,
      group : aws_identitystore_group.infra,
      permissions : [aws_ssoadmin_permission_set.view_only_access]
    },
  ]
}

module "infra_admins_to_admin_assignment" {
  for_each        = { for assignment in local.assignments : "${assignment.group.display_name} in ${assignment.account.name}" => assignment }
  source          = "./sso-account-assignment"
  account_id      = each.value.account.id
  group           = each.value.group
  permission_sets = each.value.permissions
}
