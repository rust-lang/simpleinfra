terraform {
  source = "../../../modules//docs-rs"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "dns_zone" {
  config_path = "../dns-zone"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  zone_id            = dependency.dns_zone.outputs.id
  vpc_id             = dependency.vpc.outputs.id
  private_subnet_ids = dependency.vpc.outputs.private_subnets
  domain             = "docs-rs-staging.rust-lang.net"
}
