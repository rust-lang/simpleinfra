terraform {
  source = "../../../modules//rustc-perf-collector"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
