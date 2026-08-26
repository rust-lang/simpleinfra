terraform {
  source = "../../../modules//rustc-perf-quota"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
