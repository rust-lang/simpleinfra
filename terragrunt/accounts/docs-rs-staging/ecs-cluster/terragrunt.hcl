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

inputs = {
  cluster_name = "docs-rs-staging"
  load_balancer_domain = "ecs.${dependency.dns_zone.outputs.name}"
  zone_id = dependency.dns_zone.outputs.id
}