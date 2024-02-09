locals {
  foundation_board = {
    "nell" = {
      login = "nells@microsoft.com"
      name  = "Nell Shamrell-Harrington"
    }
    "peixin" = {
      login = "peixin.hou@gmail.com"
      name  = "Peixin Hou"
    }
    "seth" = {
      login = "smarkle.aws@gmail.com"
      name  = "Seth Markle"
    }
  }
}

resource "datadog_role" "board_member" {
  name = "Board Member"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.dashboards_write,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "foundation_board" {
  name        = "Rust Foundation Board"
  description = "The board of the Rust Foundation"
  handle      = "foundation-board"
}

resource "datadog_team_membership" "foundation_board" {
  for_each = local.foundation_board

  team_id = datadog_team.foundation_board.id
  user_id = datadog_user.users[each.key].id
}
