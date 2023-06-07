terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.32"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.0.0"
    }
  }
}

provider "aws" {
  alias  = "east1"
  region = "us-east-1"
}

provider "fastly" {}
