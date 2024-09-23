terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.13.0"
    }
  }
}

provider "aws" {
  alias  = "east1"
  region = "us-east-1"
}

provider "fastly" {}
