locals {
  infra = {
    "admin"  = local.users.admin
    "jakub"  = local.users.jakub
    "jdn"    = local.users.jdn
    "mark"   = local.users.mark
    "pietro" = local.users.pietro
  }
}

resource "datadog_role" "infra" {
  name = "infra"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.logs_read_archives,
      data.datadog_permissions.all.permissions.dashboards_write,
      data.datadog_permissions.all.permissions.api_keys_read,
      data.datadog_permissions.all.permissions.api_keys_write,
      data.datadog_permissions.all.permissions.user_app_keys,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "infra" {
  name        = "infra-team"
  description = "The infra-team"
  handle      = "infra"
}

resource "datadog_team_membership" "infra" {
  for_each = local.infra

  team_id = datadog_team.infra.id
  user_id = datadog_user.users[each.key].id
}
