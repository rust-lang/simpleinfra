terraform {
  source = "../../../modules//datadog-aws"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "organization_cloudtrail" {
  config_path = "../organization-cloudtrail"
}

inputs = {
  datadog_forwarder_arns = [dependency.organization_cloudtrail.outputs.datadog_forwarder_arn]
  datadog_log_sources    = dependency.organization_cloudtrail.outputs.datadog_log_sources
  env                    = "prod"
}
