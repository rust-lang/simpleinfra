// Resources used to deploy RLA to production.

module "efs" {
  source        = "../shared/modules/efs-filesystem"
  name          = "prod--rust-log-analyzer"
  allow_subnets = data.terraform_remote_state.shared.outputs.prod_vpc.private_subnets
}
