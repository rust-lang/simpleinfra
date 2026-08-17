terraform {
  source = "../../../modules//rustc-perf-collector"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "quota" {
  config_path = "../ec2-quota"
}

inputs = {
  # Reading an output creates a Terragrunt dependency on the separately
  # applied quota request. The module also checks the account's *current*
  # quota, so a requested-but-not-yet-approved increase cannot allocate the
  # Dedicated Host and start billing it.
  required_dedicated_hosts = dependency.quota.outputs.requested_value
}
