// This Terraform files defines all our AWS container registries.
//
// To create a new registry add a new call to the module. See
// modules/ecr-repo/README.md for more information on what the module does.

module "ecr_rust_central_station" {
  source = "./modules/ecr-repo"
  name   = "rust-central-station"
}

module "ecr_rust_log_analyzer" {
  source = "./modules/ecr-repo"
  name   = "rust-log-analyzer"
}
