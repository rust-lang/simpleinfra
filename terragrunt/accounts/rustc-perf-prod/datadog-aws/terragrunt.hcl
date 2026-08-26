# Register the new account with the shared Datadog organization. The collector
# does not need a Datadog API key for this account-level EC2/CloudWatch
# integration.
terraform {
  source = "../../../modules//datadog-aws"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "prod"
}
