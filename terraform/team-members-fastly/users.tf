locals {
  users = {
    "abi" = {
      login = "abibroom@rustfoundation.org"
      name  = "Abi Broom"
      role  = "billing"
    }
    "adam" = {
      login    = "adamharvey@rustfoundation.org"
      name     = "Adam Harvey"
      role     = "engineer"
      services = local.crates_io_service_ids
    }
    "jdn" = {
      login = "jdno@jdno.dev"
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
    "syphar" = {
      login = "denis@cornehl.org"
      name  = "Denis Cornehl"
      role  = "user"
    }
    "tobias" = {
      login    = "tobiasbieniek@rustfoundation.org"
      name     = "Tobias Bieniek"
      role     = "engineer"
      services = local.crates_io_service_ids
    }
    "ubiratan" = {
      login = "ubiratansoares@rustfoundation.org"
      name  = "Ubiratan Soares"
      role  = "superuser"
    }
  }

  crates_io_service_ids = [
    "yEvEoHsDVsUDRLd6ZTxipI", # crates.io
    "t5Ms9xHxvMQ0oX8vMs88DG", # index.crates.io
    "gEfRWQihVaQqh6vsPlY0H1", # static.crates.io

    "zEKt1p82mWliIlbTQh5Hl1", # staging.crates.io
    "k8I4J4zBUYdoQ0oJt98df7", # index.staging.crates.io
    "liljrvY3Xt0CzNk0mpuLa7", # static.staging.crates.io
  ]

}

resource "fastly_user" "users" {
  for_each = local.users

  login = each.value.login
  name  = each.value.name
  role  = each.value.role
}

# Assign service permissions to users
resource "fastly_service_authorization" "users_authorization" {
  # ... expands the list into positional args so `merge` can combine them.
  for_each = merge([
    # user_name identifies fastly_user.users entries; user holds optional services.
    for user_name, user in local.users : {
      for service_id in try(user.services, []) :
      "${user_name}:${service_id}" => {
        user       = user_name
        service_id = service_id
      }
    }
  ]...)

  user_id    = fastly_user.users[each.value.user].id
  service_id = each.value.service_id
  permission = "full"
}
