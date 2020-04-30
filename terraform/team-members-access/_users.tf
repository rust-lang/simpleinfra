// This file defines all human users with access to our AWS account, and the
// groups they belong to.

locals {
  users = {
    "acrichto"     = [aws_iam_group.infra_admins.name],
    "jynelson"     = [aws_iam_group.docs_rs.name],
    "nellshamrell" = [aws_iam_group.infra_admins.name],
    "pietroalbini" = [aws_iam_group.infra_admins.name],
    "sgrif"        = [aws_iam_group.crates_io.name],
    "simulacrum"   = [aws_iam_group.infra_admins.name],
    "technetos"    = [aws_iam_group.mods_discord.name],
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

  depends_on = [aws_iam_user.users]
}
