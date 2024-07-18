locals {
  infra_admins = {
    "admin"          = local.users.admin
    "jdn"            = local.users.jdn
    "joel"           = local.users.joel
    "marcoieni"      = local.users.marcoieni
    "mark"           = local.users.mark
    "pietro"         = local.users.pietro
    "rustfoundation" = local.users.rustfoundation
  }
}

resource "datadog_team" "infra_admins" {
  name        = "Infrastructure Admins"
  description = "The infra-admins"
  handle      = "infra-admins"
}

resource "datadog_team_membership" "infra_admins" {
  for_each = local.infra_admins

  team_id = datadog_team.infra_admins.id
  user_id = datadog_user.users[each.key].id
}
