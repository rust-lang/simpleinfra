// This Terraform files defines all our AWS container registries.
//
// To create a new registry add a new call to the module. See
// modules/ecr-repo/README.md for more information on what the module does.

module "ecr_crater" {
  source = "./modules/ecr-repo"
  name = "crater"
}

module "ecr_discord_mods_bot" {
  source = "./modules/ecr-repo"
  name = "discord-mods-bot"
}

module "ecr_rust_central_station" {
  source = "./modules/ecr-repo"
  name = "rust-central-station"
}

module "ecr_rust_highfive" {
  source = "./modules/ecr-repo"
  name = "rust-highfive"
}

module "ecr_rust_log_analyzer" {
  source = "./modules/ecr-repo"
  name = "rust-log-analyzer"
}

module "ecr_rust_triagebot" {
  source = "./modules/ecr-repo"
  name = "rust-triagebot"
}
