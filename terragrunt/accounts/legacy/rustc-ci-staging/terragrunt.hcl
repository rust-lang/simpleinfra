terraform {
  source = "../../../modules//rustc-ci"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  repo = "bors-kindergarten"
}
