terraform {
  source = "../../../modules//aws-organization"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
