// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "3.30.0"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/team-members-datadog.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "datadog" {}
