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
  sentry_environment        = "prod" # "production" is used by the legacy infra
  sentry_traces_sample_rate = 0.001
  domain                    = "docs-rs-prod.rust-lang.net"
  bastion_security_group_id = dependency.vpc.outputs.bastion_security_group_id
  web_count                 = 2
  builder_count             = 2
  builder_config = {
    # 16 vCPU, 32 GiB RAM: headroom for 12-vCPU builds and 12 GiB memory exceptions.
    instance_type      = "c8i.4xlarge"
    build_cpu_limit    = 12
    build_memory_limit = "6GiB" # default; per-crate exceptions can raise this.
    # Current legacy EBS performance.
    volume_iops       = 8000
    volume_throughput = 1000
  }
  db_instance_class = "db.m6i.large" # 2 vCPUs. 8 GiB RAM.

  # One-time ~10TB migration from the legacy bucket managed in terraform/docs-rs.
  s3_migration_enabled            = true
  s3_migration_source_bucket_name = "rust-docs-rs"

  # Event-driven replication from legacy docs.rs bucket.
  s3_crr_enabled = true
}
