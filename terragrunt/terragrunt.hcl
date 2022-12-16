locals {
  # Due to Terragrunt limitations, we can't generate all the variables we need
  # within this file. Because of that, we invoke a Python script to generate
  # those variables for us.
  cmd = jsondecode(run_cmd("--terragrunt-quiet", "${get_parent_terragrunt_dir()}/terragrunt-locals.py", get_original_terragrunt_dir()))
}

remote_state {
  backend = "s3"
  generate = {
    path      = "terragrunt-generated-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    profile        = "${local.cmd.remote_state_profile}"
    bucket         = "${local.cmd.remote_state_bucket}"
    dynamodb_table = "${local.cmd.remote_state_dynamodb_table}"
    region         = "${local.cmd.remote_state_region}"
    key            = "${local.cmd.remote_state_key}"
  }
}

generate "providers" {
  path = "terragrunt-generated-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = local.cmd.providers_content
}
