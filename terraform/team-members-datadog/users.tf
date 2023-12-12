locals {
  users = {
    "admin" = {
      login = "admin@rust-lang.org"
      name  = "Rust Admin"
      roles = ["Datadog Admin Role"]
    }
    "jdn" = {
      login = "jandavidnose@rustfoundation.org"
      name  = "Jan David Nose"
      roles = ["Datadog Admin Role"]
    }
    "joel" = {
      login = "joelmarcey@rustfoundation.org"
      name  = "Joel Marcey"
      roles = ["Datadog Admin Role"]
    }
    "mark" = {
      login = "mark.simulacrum@gmail.com"
      name  = "Mark Rousskov"
      roles = ["DataDog Admin Role"]
    }
    "nell" = {
      login = "nells@microsoft.com"
      name  = "Nell Shamrell-Harrington"
      roles = ["Board Member"]
    }
    "paullenz" = {
      login = "paullenz@rustfoundation.org"
      name  = "Paul Lenz"
      roles = ["Datadog Read Only Role"]
    }
    "peixin" = {
      login = "peixin.hou@gmail.com"
      name  = "Peixin Hou"
      roles = ["Board Member"]
    }
    "pietro" = {
      login = "pietro@pietroalbini.org"
      name  = "Pietro Albini"
      roles = ["DataDog Admin Role"]
    }
    "rustfoundation" = {
      login = "infra@rustfoundation.org"
      name  = "Rust Foundation Infrastructure"
      roles = ["Datadog Admin Role"]
    }
    "seth" = {
      login = "smarkle.aws@gmail.com"
      name  = "Seth Markle"
      roles = ["Board Member"]
    }
    "tobias" = {
      login = "tobiasbieniek@rustfoundation.org"
      name  = "Tobias Bieniek"
      roles = ["Datadog Standard Role", "crates.io"]
    }
  }
}

data "datadog_role" "role" {
  for_each = toset(flatten(values({
    for index, user in local.users : user.login => user.roles
  })))

  filter = each.value
}

resource "datadog_user" "users" {
  for_each = local.users

  email                = each.value.login
  name                 = each.value.name
  roles                = [for role in each.value.roles : data.datadog_role.role[role].id]
  send_user_invitation = true
}
