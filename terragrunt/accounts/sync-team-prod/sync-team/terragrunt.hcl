terraform {
  source = "../../../modules//sync-team"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
