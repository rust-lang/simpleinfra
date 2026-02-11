terraform {
  source = "../../../modules//ecs-cluster"
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
  cluster_name         = "docs-rs-prod"
  load_balancer_domain = "ecs.${dependency.dns_zone.outputs.name}"
  zone_id              = dependency.dns_zone.outputs.id
  vpc_id               = dependency.vpc.outputs.id
  subnet_ids           = dependency.vpc.outputs.public_subnets
}
