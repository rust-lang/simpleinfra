// Configuration for Terraform itself.

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "4.25.0"
    }
  }

  backend "s3" {
    bucket       = "rust-terraform"
    key          = "simpleinfra/team-members-datadog.tfstate"
    region       = "us-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "datadog" {}
