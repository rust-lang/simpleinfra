data "aws_ssoadmin_instances" "sso" {}

locals {
  group_permissions = flatten([for group in var.groups : [for permission in group.permissions : { group : group.group, permission : permission }]])
}

resource "aws_ssoadmin_account_assignment" "account_group_permission" {
  for_each           = { for group_permission in local.group_permissions : "${group_permission.group.display_name}[${group_permission.permission.name}]" => group_permission }
  instance_arn       = (data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = each.value.permission.arn

  principal_id   = each.value.group.group_id
  principal_type = "GROUP"

  target_id   = var.account_id
  target_type = "AWS_ACCOUNT"
}

variable "account_id" {
  type        = string
  description = "The Amazon account id tha the group is being assigned to"
}

variable "groups" {
  type = list(object({
    group : object({ display_name : string, group_id : string }),
    permissions : list(object({ name : string, arn : string }))
  }))
  description = "The groups being assigned to the account with their permissions"
}
