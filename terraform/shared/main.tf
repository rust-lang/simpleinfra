terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/shared.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  version = "~> 2.44"

  profile = "default"
  region  = "us-west-1"
}

provider "aws" {
  version = "~> 2.44"

  profile = "default"
  region  = "us-east-1"
  alias   = "east1"
}

provider "dns" {
  version = "~> 2.2"
}

locals {
  // Users allowed to connect to the bastion through SSH. Each user needs to
  // have the CIDR of the static IP they want to connect from stored in AWS SSM
  // Parameter Store (us-west-1), in a string key named:
  //
  //     /prod/bastion/allowed-ips/${user}
  //
  allowed_users = [
    "acrichto",
    "aidanhs",
    "guillaumegomez",
    "joshua",
    "mozilla-mountain-view",
    "mozilla-portland",
    "mozilla-san-francisco",
    "onur",
    "pietro",
    "shep",
    "simulacrum",
  ]
}

data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}
