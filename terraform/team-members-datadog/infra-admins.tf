locals {
  infra_admins = {
    "admin" = {
      login = "admin@rust-lang.org"
      name  = "Rust Admin"
    }
    "jdn" = {
      login = "jandavidnose@rustfoundation.org"
      name  = "Jan David Nose"
    }
    "joel" = {
      login = "joelmarcey@rustfoundation.org"
      name  = "Joel Marcey"
    }
    "mark" = {
      login = "mark.simulacrum@gmail.com"
      name  = "Mark Rousskov"
    }
    "pietro" = {
      login = "pietro@pietroalbini.org"
      name  = "Pietro Albini"
    }
    "rustfoundation" = {
      login = "infra@rustfoundation.org"
      name  = "Rust Foundation Infrastructure"
    }
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
