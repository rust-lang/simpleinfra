terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/shared.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "east1"
}

data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}
