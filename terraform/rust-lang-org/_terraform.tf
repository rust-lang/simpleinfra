// Configuration for Terraform itself.

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.41.0"
    }
  }

  backend "s3" {
    bucket       = "rust-terraform"
    key          = "simpleinfra/rust-lang-org.tfstate"
    region       = "us-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
