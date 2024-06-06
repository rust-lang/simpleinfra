locals {
  crates_io = {
    "adam"   = local.users.adam
    "tobias" = local.users.tobias
  }
}

resource "datadog_role" "crates_io" {
  name = "crates.io"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.logs_read_archives,
      data.datadog_permissions.all.permissions.dashboards_write,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "crates_io" {
  name        = "crates.io"
  description = "The team working on crates.io"
  handle      = "crates-io"
}

resource "datadog_team_membership" "crates_io" {
  for_each = local.crates_io

  team_id = datadog_team.crates_io.id
  user_id = datadog_user.users[each.key].id
}
