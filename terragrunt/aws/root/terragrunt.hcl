remote_state {
  backend = "s3"
  generate = {
    path      = "terragrunt-generated-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terraform-state-${get_aws_account_id()}"
    dynamodb_table = "terraform-lock"
    region         = "us-east-1"
    key            = "${path_relative_to_include()}.tfstate"
  }
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
  }
}
