terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.9"
    }
  }
}
