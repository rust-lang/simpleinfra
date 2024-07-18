terraform {
  source = "../../../modules//aws-organization"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  users = {
    "jdno" = {
      given_name  = "Jan David",
      family_name = "Nose"
      email       = "jandavidnose@rustfoundation.org"
      groups      = ["infra", "infra-admins"]
    }
    "pietroalbini" = {
      given_name  = "Pietro",
      family_name = "Albini"
      email       = "pietro@pietroalbini.org"
      groups      = ["infra", "infra-admins", "release"]
    }
    "simulacrum" = {
      given_name  = "Mark",
      family_name = "Rousskov"
      email       = "mark.simulacrum@gmail.com"
      groups      = ["infra", "infra-admins", "release", "triagebot"]
    }
    "rylev" = {
      given_name  = "Ryan",
      family_name = "Levick"
      email       = "me@ryanlevick.com"
      groups      = ["infra"]
    }
    "shepmaster" = {
      given_name  = "Jake",
      family_name = "Goulding",
      email       = "jake.goulding@integer32.com"
      groups      = ["infra"]
    }
    "abibroom" = {
      given_name = "Abi"
      family_name = "Broom"
      email = "abibroom@rustfoundation.org"
      groups = ["billing"]
    }
    "joelmarcey" = {
      given_name = "Joel"
      family_name = "Marcey"
      email = "joelmarcey@rustfoundation.org"
      groups = ["billing"]
    }
    "kobzol" = {
      given_name = "Jakub"
      family_name = "Beránek"
      email = "berykubik@gmail.com"
      groups = ["infra"]
    }
    "tobias" = {
      given_name = "Tobias"
      family_name = "Bieniek"
      email = "tobias@bieniek.cloud"
      groups = ["crates-io"]
    }
    "adam" = {
      given_name = "Adam"
      family_name = "Harvey"
      email = "adam@adamharvey.name"
      groups = ["crates-io"]
    }
    "ehuss" = {
      given_name = "Eric"
      family_name = "Huss"
      email = "eric@huss.org"
      groups = ["triagebot"]
    }
    "apiraino" = {
      given_name = "apiraino"
      family_name = "n/a"
      email = "apiraino@protonmail.com"
      groups = ["triagebot"]
    }
    "marcoieni" = {
      given_name  = "Marco",
      family_name = "Ieni"
      email       = "marcoieni@rustfoundation.org"
      groups      = ["infra", "infra-admins"]
    }
  }
}
