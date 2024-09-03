// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.3"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.14"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "aws" {
  region  = "us-east-1"
  alias   = "us-east-1"
  profile = "sync-team-prod"
}
