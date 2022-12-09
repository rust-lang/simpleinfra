locals {
  subscription_id = "ff8cd1a5-37b4-4c55-a8db-b48366d902e0"
}

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
  subscription_id = local.subscription_id
}
