locals {
  foundation = {
    "adam"           = local.users.adam
    "jdn"            = local.users.jdn
    "joel"           = local.users.joel
    "paullenz"       = local.users.paullenz
    "rustfoundation" = local.users.rustfoundation
    "tobias"         = local.users.tobias
  }
}

resource "datadog_role" "foundation" {
  name = "Rust Foundation"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.dashboards_write,
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
