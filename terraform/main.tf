terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

data "aws_caller_identity" "current" {}
