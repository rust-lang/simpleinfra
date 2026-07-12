terraform {
  source = "../../../modules//promote-release"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "staging"
}
