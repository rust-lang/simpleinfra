locals {
  crater = {
    "walter" = local.users.walter
  }
}

resource "datadog_role" "crater" {
  name = "crater"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.dashboards_write,
      data.datadog_permissions.all.permissions.notebooks_write,
      data.datadog_permissions.all.permissions.api_keys_read,
      data.datadog_permissions.all.permissions.user_app_keys,
      data.datadog_permissions.all.permissions.dbm_read,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "crater" {
  name        = "crater"
  description = "The team maintaining crater"
  handle      = "crater"
}

resource "datadog_team_membership" "crater" {
  for_each = local.crater

  team_id = datadog_team.crater.id
  user_id = datadog_user.users[each.key].id
}
