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
  github_environment        = "production"
  domain                    = "docs-rs-prod.rust-lang.net"
  bastion_security_group_id = dependency.vpc.outputs.bastion_security_group_id
  builder_instance_type     = "c6a.8xlarge" # 32 vCPU. 64 GiB RAM.
  db_instance_class         = "db.m6i.large" # 2 vCPUs. 8 GiB RAM.

  # Fastly CDN configuration.
  # The docs.rs apex domain is still served by the legacy terraform/docs-rs setup.
  # This CDN serves the internal domain to avoid conflicts during migration.
  cdn_domain_name = "docs-rs-prod.rust-lang.net"
  cdn_origin      = dependency.cluster.outputs.config.lb_domain

  # One-time ~10TB migration from the legacy bucket managed in terraform/docs-rs.
  s3_migration_enabled            = true
  s3_migration_source_bucket_name = "rust-docs-rs"

  # Event-driven replication from legacy docs.rs bucket.
  s3_crr_enabled = true
}
