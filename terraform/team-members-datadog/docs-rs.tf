locals {
  docs_rs = {
    "guillaumegomez" = local.users.guillaumegomez
    "syphar"         = local.users.syphar
  }
}

resource "datadog_role" "docs_rs" {
  name = "docs.rs"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.logs_write_pipelines,
      data.datadog_permissions.all.permissions.logs_write_processors,
      data.datadog_permissions.all.permissions.logs_read_archives,
      data.datadog_permissions.all.permissions.dashboards_write,
      data.datadog_permissions.all.permissions.monitors_write,
      data.datadog_permissions.all.permissions.monitors_downtime,
      data.datadog_permissions.all.permissions.notebooks_write,
      data.datadog_permissions.all.permissions.dbm_read,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "docs_rs" {
  name        = "docs.rs"
  description = "The team working on docs.rs"
  handle      = "docs-rs"
}

resource "datadog_team_membership" "docs_rs" {
  for_each = local.docs_rs

  team_id = datadog_team.docs_rs.id
  user_id = datadog_user.users[each.key].id
}
