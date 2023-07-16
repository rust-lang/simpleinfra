terraform {
  source = "../../../modules//bors"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
