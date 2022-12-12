terraform {
  source = "../../../modules//ecs-cluster"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  cluster_name = "docs-rs-staging"
  load_balancer_domain = "ecs-docs-rs-staging.infra.rust-lang.org"
  load_balancer_subnet_ids = []
  vpc_id = "TODO"
  subnet_ids = []
}