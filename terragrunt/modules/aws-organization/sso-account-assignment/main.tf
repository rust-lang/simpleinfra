data "aws_ssoadmin_instances" "sso" {}

resource "aws_ssoadmin_account_assignment" "account_group_permission" {
  for_each           = { for permission_set in var.permission_sets : "${var.group.display_name}[${permission_set.name}]" => permission_set.arn }
  instance_arn       = (data.aws_ssoadmin_instances.sso.arns)[0]
  permission_set_arn = each.value

  principal_id   = var.group.group_id
  principal_type = "GROUP"

  target_id   = var.account_id
  target_type = "AWS_ACCOUNT"
}

variable "account_id" {
  type        = string
  description = "The Amazon account id tha the group is being assigned to"
}

variable "group" {
  type        = object({ display_name : string, group_id : string })
  description = "The group being assigned to the account"
}

variable "permission_sets" {
  type        = list(object({ name : string, arn : string }))
  description = "The permission sets that the group should have"
}
