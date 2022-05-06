// This terraform module imports all the services from the services/ directory,
// and configures them.

module "service_ecs_cluster" {
  source = "./services/ecs-cluster"

  cluster_name             = "rust-ecs-prod"
  load_balancer_domain     = "ecs-prod.infra.rust-lang.org"
  load_balancer_subnet_ids = module.vpc_prod.public_subnets
  vpc_id                   = module.vpc_prod.id
  subnet_ids               = module.vpc_prod.private_subnets
}

module "service_triagebot" {
  source = "./services/triagebot"

  domain_name    = "triagebot.infra.rust-lang.org"
  cluster_config = module.service_ecs_cluster.config
}
