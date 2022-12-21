terraform {
  source = "../../../modules//vpc"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  name      = "docs-rs-staging"
  ipv4_cidr = "10.0.0.0/16"

  public_subnets = {
    0 = "use1-az1",
    1 = "use1-az2",
  }
  private_subnets = {
    2 = "use1-az1",
  }
}
