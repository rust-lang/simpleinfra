// Configuration for Terraform itself.

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/team-repo.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "external" {
  version = "~> 1.2"
}

provider "aws" {
  version = "~> 2.44"

  profile = "default"
  region  = "us-west-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
