module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "crater"
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 4.23"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.2.3"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/crater.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "google" {
  project = "rust-crater"
}

locals {
  regions = {
    "us-central1" = 15, // max capacity: 24 instances (384 cores)
    "us-east5" = 4, // max capacity: 8 instances (128 cores)
  }
}
