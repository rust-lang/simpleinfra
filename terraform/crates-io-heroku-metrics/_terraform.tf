// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.14"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/crates-io-heroku-metrics.tfstate"
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
  region  = "us-west-1"
}
