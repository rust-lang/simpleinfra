terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  version = "~> 2.43"
  profile = "default"
  region  = "us-west-1"
}

provider "aws" {
  version = "~> 2.43"
  profile = "default"
  region  = "us-east-1"
  alias   = "east1"
}

data "aws_caller_identity" "current" {}
