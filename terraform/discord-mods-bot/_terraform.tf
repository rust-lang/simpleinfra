// Configuration for Terraform itself.

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/discord-mods-bot.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  version = "~> 2.44"

  profile = "default"
  region  = "us-west-1"
}
