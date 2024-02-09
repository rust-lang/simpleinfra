locals {
  foundation = {
    "paullenz" = {
      login = "paullenz@rustfoundation.org"
      name  = "Paul Lenz"
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
