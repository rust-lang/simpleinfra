terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.0.0"
    }
  }
}

