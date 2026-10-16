// Configuration for Terraform itself.

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
  }

  backend "s3" {
    bucket       = "rust-terraform"
    key          = "simpleinfra/dns-delegation.tfstate"
    region       = "us-west-1"
    use_lockfile = true
    encrypt      = true
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
  region = "us-west-1"
}
