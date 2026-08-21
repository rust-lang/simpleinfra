terraform {
  source = "../../../modules//datadog-aws"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

# Tell Terragrunt to apply aws-organization first
dependencies {
  paths = ["../aws-organization"]
}

inputs = {
  cloudtrail_datadog_api_key_secret_name = "/prod/datadog/cloudtrail-api-key"
  env                                    = "prod"
}
