terraform {
  source = "../../../modules//bors"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domain = "bors-staging.rust-lang.net"
}
