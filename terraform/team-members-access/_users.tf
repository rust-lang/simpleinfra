// This file defines all human users with access to our AWS account, and the
// groups they belong to.

locals {
  users = {
    "acrichto"     = [aws_iam_group.infra_admins.name],
    "jynelson"     = [aws_iam_group.docs_rs.name],
    "pietroalbini" = [aws_iam_group.infra_admins.name],
    "simulacrum"   = [aws_iam_group.infra_admins.name],
  }
}

resource "aws_iam_user" "users" {
  for_each = local.users
  name     = each.key
}

resource "aws_iam_user_group_membership" "users" {
  for_each = local.users
  user     = each.key
  groups   = each.value
}
