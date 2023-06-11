terraform {
  source = "../../../modules//dns-zone"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  name = "bors-staging.rust-lang.net"
}
