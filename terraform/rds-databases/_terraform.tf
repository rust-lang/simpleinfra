// Configuration for Terraform itself.

terraform {
  required_version = ">= 0.12"

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

provider "random" {
  version = "~> 2.2"
}

provider "postgresql" {
  version = "~> 1.5"

  host            = aws_db_instance.shared.address
  port            = aws_db_instance.shared.port
  database        = "postgres"
  username        = aws_db_instance.shared.username
  password        = aws_db_instance.shared.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}
