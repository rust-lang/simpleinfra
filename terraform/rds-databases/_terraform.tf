// Configuration for Terraform itself.

terraform {
  required_version = "~> 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 1.2.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.7.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.3.0"
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
  version = "~> 2.44"

  profile = "default"
  region  = "us-west-1"
}

// Setup port forwarding to access the database through the bastion.
data "external" "port_forwarding" {
  program = ["${path.module}/forward-ports.py"]
  query = {
    bastion    = "bastion.infra.rust-lang.org"
    cache-name = "shared"
    timeout    = 600 // 10 minutes
    address    = aws_db_instance.shared.address
    port       = aws_db_instance.shared.port
  }
}

provider "postgresql" {
  host            = data.external.port_forwarding.result.host
  port            = data.external.port_forwarding.result.port
  database        = "postgres"
  username        = aws_db_instance.shared.username
  password        = aws_db_instance.shared.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}
