locals {
  foundation = {
    "adam" = {
      login = "adamharvey@rustfoundation.org"
      name  = "Adam Harvey"
    }
    "jdn" = {
      login = "jandavidnose@rustfoundation.org"
      name  = "Jan David Nose"
    }
    "joel" = {
      login = "joelmarcey@rustfoundation.org"
      name  = "Joel Marcey"
    }
    "paullenz" = {
      login = "paullenz@rustfoundation.org"
      name  = "Paul Lenz"
    }
    "rustfoundation" = {
      login = "infra@rustfoundation.org"
      name  = "Rust Foundation Infrastructure"
    }
    "tobias" = {
      login = "tobiasbieniek@rustfoundation.org"
      name  = "Tobias Bieniek"
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
