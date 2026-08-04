locals {
  on_call = {
    "adam"      = local.users.adam
    "joel"      = local.users.joel
    "marcoieni" = local.users.marcoieni
    "tobias"    = local.users.tobias
    "ubiratan"  = local.users.ubiratan
    "walter"    = local.users.walter
  }
}

resource "datadog_team" "on_call" {
  name        = "On-Call"
  description = ""
  handle      = "on-call"
}

resource "datadog_team_membership" "on_call" {
  for_each = local.on_call

  team_id = datadog_team.on_call.id
  user_id = datadog_user.users[each.key].id
}
