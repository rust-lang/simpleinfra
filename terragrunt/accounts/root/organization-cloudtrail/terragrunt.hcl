terraform {
  source = "../../../modules//organization-cloudtrail"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

# CloudTrail trusted access must be enabled before creating an organization trail.
dependencies {
  paths = ["../aws-organization"]
}
