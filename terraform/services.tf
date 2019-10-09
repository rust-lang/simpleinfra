// This terraform module imports all the services from the services/ directory,
// and configures them.

module "service_crater" {
  source   = "./services/crater"
  ecr_repo = module.ecr_crater
}
