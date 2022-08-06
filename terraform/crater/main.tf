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
  groups = {
    "us-central1-n2d" = {
      region        = "us-central1",
      instance_type = "n2d-highcpu-16",
      // Current max capacity - 24 instances, 384 cores
      count = 20,
    },
    "us-east1-n2d" = {
      region        = "us-east5",
      instance_type = "n2d-highcpu-16",
      // Current max capacity - 5 instances, 80 cores
      count = 5,
    },
    "us-central1-c2d" = {
      region        = "us-central1",
      instance_type = "c2d-highcpu-8",
      count         = 7,
    },
  }
}
