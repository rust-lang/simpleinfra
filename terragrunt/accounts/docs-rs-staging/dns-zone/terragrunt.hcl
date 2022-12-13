terraform {
  source = "../../../modules//dns-zone"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  name = "docs-rs-staging.rust-lang.net"
}
