// Configuration for Terraform itself.

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2.3"
    }
  }

  backend "s3" {
    bucket       = "rust-terraform"
    key          = "simpleinfra/rust-log-analyzer.tfstate"
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

provider "aws" {
  region = "us-east-1"
  alias  = "east1"
}
