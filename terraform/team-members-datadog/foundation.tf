locals {
  foundation = {
    "adam"           = local.users.adam
    "joel"           = local.users.joel
    "marcoieni"      = local.users.marcoieni
    "rustfoundation" = local.users.rustfoundation
    "tobias"         = local.users.tobias
    "ubiratan"       = local.users.ubiratan
    "walter"         = local.users.walter
  }

  # Foundation members inherit all permissions from Datadog's Standard Role.
  foundation_roles = [
    "Datadog Standard Role",
    datadog_role.foundation.name,
  ]
}

resource "datadog_role" "foundation" {
  name = "Rust Foundation"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.dashboards_write,
      data.datadog_permissions.all.permissions.dashboards_public_share,
      data.datadog_permissions.all.permissions.notebooks_write,
      data.datadog_permissions.all.permissions.logs_modify_indexes,
      data.datadog_permissions.all.permissions.logs_write_exclusion_filters,
      data.datadog_permissions.all.permissions.logs_generate_metrics,
      data.datadog_permissions.all.permissions.metrics_metadata_write,
      data.datadog_permissions.all.permissions.monitors_write,
      data.datadog_permissions.all.permissions.dbm_read,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_team" "foundation" {
  name        = "Rust Foundation"
  description = "The staff of the Rust Foundation"
  handle      = "foundation"
}

resource "datadog_team_membership" "foundation" {
  for_each = local.foundation

  team_id = datadog_team.foundation.id
  user_id = datadog_user.users[each.key].id
}
