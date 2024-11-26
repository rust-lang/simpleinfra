locals {
  users = {
    "abi" = {
      login = "abibroom@rustfoundation.org"
      name  = "Abi Broom"
      role  = "billing"
    }
    "jdn" = {
      login = "jandavidnose@rustfoundation.org"
      name  = "Jan David Nose"
      role  = "superuser"
    }
    "joel" = {
      login = "joelmarcey@rustfoundation.org"
      name  = "Joel Marcey"
      role  = "superuser"
    }
    "marcoieni" = {
      login = "marcoieni@rustfoundation.org"
      name  = "Marco Ieni"
      role  = "superuser"
    }
    "mark" = {
      login = "mark.simulacrum@gmail.com"
      name  = "Mark Rousskov"
      role  = "superuser"
    }
    "paul" = {
      login = "paullenz@rustfoundation.org"
      name  = "Paul Lenz"
      role  = "billing"
    }
    "pietro" = {
      login = "pietro@pietroalbini.org"
      name  = "Pietro Albini"
      role  = "superuser"
    }
    "rustadmin" = {
      login = "admin@rust-lang.org"
      name  = "Rust Admin"
      role  = "superuser"
    }
    "rustfoundation" = {
      login = "infra@rustfoundation.org"
      name  = "Rust Foundation Infrastructure"
      role  = "superuser"
    }
  }
}

resource "fastly_user" "users" {
  for_each = local.users

  login = each.value.login
  name  = each.value.name
  role  = each.value.role
}
