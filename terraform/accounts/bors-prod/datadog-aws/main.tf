module "datadog_aws" {
  source = "../../../../terragrunt/modules/datadog-aws"

  env = "prod"
}
