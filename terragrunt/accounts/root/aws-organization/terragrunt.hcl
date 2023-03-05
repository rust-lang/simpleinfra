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
      groups      = ["infra", "infra-admins"]
    }
    "simulacrum" = {
      given_name  = "Mark",
      family_name = "Rousskov"
      email       = "mark.simulacrum@gmail.com"
      groups      = ["infra", "infra-admins"]
    }
    "rylev" = {
      given_name  = "Ryan",
      family_name = "Levick"
      email       = "me@ryanlevick.com"
      groups      = ["infra"]
    }
    "jynelson" = {
      given_name  = "Joshua",
      family_name = "Nelson",
      email       = "rust@jyn.dev"
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
  }
}
