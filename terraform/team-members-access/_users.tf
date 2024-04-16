// This file defines all human users with access to our AWS account, and the
// groups they belong to.

locals {
  users = {
    "jynelson"      = [aws_iam_group.docs_rs.name, aws_iam_group.infra_team.name],
    "pietroalbini"  = [aws_iam_group.infra_admins.name],
    "simulacrum"    = [aws_iam_group.infra_admins.name],
    "jdn"           = [aws_iam_group.infra_admins.name],
    "technetos"     = [aws_iam_group.mods_discord.name],
    "carols10cents" = [aws_iam_group.crates_io.name],
    "jtgeibel"      = [aws_iam_group.crates_io.name],
    "Turbo87"       = [aws_iam_group.crates_io.name],
    "rylev"         = [aws_iam_group.rustc_perf.name, aws_iam_group.infra_team.name],
    "JoelMarcey"    = [aws_iam_group.foundation.name],
    "rebeccarumbul" = [aws_iam_group.foundation.name],
    "abibroom"      = [aws_iam_group.foundation.name],
    "paullenz"      = [aws_iam_group.foundation.name],
    "shepmaster"    = [aws_iam_group.infra_deploy_playground.name, aws_iam_group.infra_team.name],
    "oli-obk"       = [aws_iam_group.infra_deploy_staging_dev_desktop.name],
    "LawnGnome"     = [aws_iam_group.crates_io.name],
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
