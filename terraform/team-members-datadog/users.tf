locals {
  users = {
    "admin" = {
      login = "admin@rust-lang.org"
      name  = "Rust Admin"
      role  = "Datadog Admin Role"
    }
    "jdn" = {
      login = "jandavidnose@rustfoundation.org"
      name  = "Jan David Nose"
      role  = "Datadog Admin Role"
    }
    "joel" = {
      login = "joelmarcey@rustfoundation.org"
      name  = "Joel Marcey"
      role  = "Datadog Admin Role"
    }
    "mark" = {
      login = "mark.simulacrum@gmail.com"
      name  = "Mark Rousskov"
      role  = "DataDog Admin Role"
    }
    "paullenz" = {
      login = "paullenz@rustfoundation.org"
      name  = "Paul Lenz"
      role  = "Datadog Read Only Role"
    }
    "pietro" = {
      login = "pietro@pietroalbini.org"
      name  = "Pietro Albini"
      role  = "DataDog Admin Role"
    }
    "rustfoundation" = {
      login = "infra@rustfoundation.org"
      name  = "Rust Foundation Infrastructure"
      role  = "Datadog Admin Role"
    }
    "tobias" = {
      login = "tobiasbieniek@rustfoundation.org"
      name  = "Tobias Bieniek"
      role  = "Datadog Standard Role"
    }
  }
}

data "datadog_role" "role" {
  for_each = toset(values({
    for index, user in local.users : user.login => user.role
  }))

  filter = each.value
}

resource "datadog_user" "users" {
  for_each = local.users

  email                = each.value.login
  name                 = each.value.name
  roles                = [data.datadog_role.role[each.value.role].id]
  send_user_invitation = true
}
