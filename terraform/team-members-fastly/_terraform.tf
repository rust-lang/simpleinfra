// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "5.13.0"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/team-members-fastly.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "fastly" {}
