terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.11.0"
    }
  }
}
