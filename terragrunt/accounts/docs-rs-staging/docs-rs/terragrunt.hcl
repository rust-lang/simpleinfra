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

dependency "cluster" {
  config_path = "../ecs-cluster"
}

inputs = {
  zone_id                   = dependency.dns_zone.outputs.id
  cluster_config            = dependency.cluster.outputs.config
  private_subnet_ids        = dependency.vpc.outputs.private_subnets
  github_environment        = "staging"
  domain                    = "docs-rs-staging.rust-lang.net"
  bastion_security_group_id = dependency.vpc.outputs.bastion_security_group_id
  builder_instance_type     = "c6a.large" # 2 vCPU. 4 GiB RAM.
  db_instance_class         = "db.t4g.small" # 2 vCPUs. 2 GiB RAM.

  # Fastly CDN configuration
  cdn_domain_name = "docs-rs-staging.rust-lang.net"
  cdn_origin      = dependency.cluster.outputs.config.lb_domain
}
