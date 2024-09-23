locals {
  crates_io_oncall = {
    "andrei_listochkin" = local.users.andrei_listochkin
    "felix_gilcher"     = local.users.felix_gilcher
    "florian_gilcher"   = local.users.florian_gilcher
    "pietro_albini"     = local.users.pietro_albini
    "sebastian_ziebell" = local.users.sebastian_ziebell
    "thepang_mbambo"    = local.users.tshepang_mbambo
    "lukas_wirth"       = local.users.lukas_wirth
  }
}

resource "datadog_role" "crates_io_oncall" {
  name = "crates.io on-call"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "crates_io_oncall" {
  name        = "crates.io on-call"
  description = "The on-call team for crates.io"
  handle      = "crates-io-oncall"
}

resource "datadog_team_membership" "crates_io_oncall" {
  for_each = local.crates_io_oncall

  team_id = datadog_team.crates_io_oncall.id
  user_id = datadog_user.users[each.key].id
}
