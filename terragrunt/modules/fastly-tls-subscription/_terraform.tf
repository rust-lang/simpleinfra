terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "~> 8.6"
    }
  }
}
