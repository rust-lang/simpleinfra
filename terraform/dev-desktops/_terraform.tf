// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/dev-desktop.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

provider "aws" {
  alias   = "eu-central-1"
  profile = "default"
  region  = "eu-central-1"
}

provider "aws" {
  alias   = "us-east-1"
  profile = "default"
  region  = "us-east-1"
}
