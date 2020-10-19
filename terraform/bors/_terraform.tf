// Configuration for Terraform itself.

terraform {
  required_version = "~> 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    github = {
      source  = "hashicorp/github"
      version = "~> 2.9.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/bors.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "github" {
  organization = var.github_org
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}

variable "domain_name" {
  type = string
}

variable "legacy_domain_names" {
  type = list(string)
}

variable "github_org" {
  type = string
}

variable "repositories" {
  type = map(string)
}
