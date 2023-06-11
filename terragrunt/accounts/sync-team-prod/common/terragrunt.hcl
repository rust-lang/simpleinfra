terraform {
  source = "../../../modules//common"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
