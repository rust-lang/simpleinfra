// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/rds-databases.tfstate"
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

provider "postgresql" {
  host            = "127.0.0.1"
  port            = "57467"
  database        = "postgres"
  username        = aws_db_instance.shared.username
  password        = aws_db_instance.shared.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}
