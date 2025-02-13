terraform {
  source = "../../../modules//rustc-ci"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  repo              = "rust"
  caches_bucket     = "rust-lang-ci-sccache2"
  artifacts_bucket  = "rust-lang-ci2"
}
