// Configuration for Terraform itself.

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.7.2"
    }
  }

  backend "s3" {
    bucket       = "rust-terraform"
    key          = "simpleinfra/team-members-fastly.tfstate"
    region       = "us-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "fastly" {}
