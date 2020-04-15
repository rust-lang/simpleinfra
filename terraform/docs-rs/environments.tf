module "staging" {
  source = "./impl"

  env_name = "staging"

  ci_username            = aws_iam_user.ci.name
  inventories_bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
}
