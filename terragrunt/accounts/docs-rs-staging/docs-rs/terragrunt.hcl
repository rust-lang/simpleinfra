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
  sentry_environment        = "staging"
  sentry_traces_sample_rate = 0.001
  domain                    = "docs-rs-staging.rust-lang.net"
  bastion_security_group_id = dependency.vpc.outputs.bastion_security_group_id
  builder_image_version     = "latest" # Prefer a published SHA tag or digest for repeatable rollouts.
  web_count                 = 2
  builder_count             = 2
  builder_config = {
    # Each host: 4 vCPU, 8 GiB RAM, with a 6 GiB build limit.
    instance_type      = "c8i.xlarge"
    build_cpu_limit    = 3
    build_memory_limit = "6GiB"
  }
  db_instance_class = "db.t4g.small" # 2 vCPUs. 2 GiB RAM.
}
