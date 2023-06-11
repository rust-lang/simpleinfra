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

