// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
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
  owner = var.github_org
}

provider "github" {
  alias = "rust_lang_ci"
  owner = "rust-lang-ci"
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
