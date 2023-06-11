terraform {
  source = "../../../modules//dns-zone"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  name = "sync-team-prod.rust-lang.net"
}
