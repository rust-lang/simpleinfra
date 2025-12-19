terraform {
  source = "../../../modules//vpc"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "dns_zone" {
  config_path = "../dns-zone"
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
    3 = "use1-az2",
  }
  zone_id = dependency.dns_zone.outputs.id
  bastion_users = ["marcoieni", "syphar"]
}
