// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.3"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2.3"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/team-repo.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}
