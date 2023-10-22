// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/rustc-ci.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "east1"
  region = "us-east-1"
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}
