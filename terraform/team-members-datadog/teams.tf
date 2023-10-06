locals {
  infra_admins = {
    admin  = datadog_user.users["admin"].id,
    jdn    = datadog_user.users["jdn"].id,
    mark   = datadog_user.users["mark"].id,
    pietro = datadog_user.users["pietro"].id,
  }
}

resource "datadog_team" "infra_admins" {
  description = "Administrators of the infra-team"
  handle      = "infra-admins"
  name        = "infra-admins"
}

resource "datadog_team_membership" "infra_admins" {
  for_each = local.infra_admins

  team_id = datadog_team.infra_admins.id
  user_id = each.value
}

resource "datadog_team" "infra" {
  description = "The infrastructure team"
  handle      = "infra"
  name        = "infra"
}

resource "datadog_team_membership" "infra" {
  for_each = merge(local.infra_admins, {
  })

  team_id = datadog_team.infra.id
  user_id = each.value
}

resource "datadog_team" "crates_io" {
  description = "The crates.io team"
  handle      = "crates-io"
  name        = "crates.io"
}

resource "datadog_team_membership" "crates_io" {
  for_each = merge(local.infra_admins, {
    tobias = datadog_user.users["tobias"].id,
  })

  team_id = datadog_team.crates_io.id
  user_id = each.value
}
