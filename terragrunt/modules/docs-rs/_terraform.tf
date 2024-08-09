terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.32"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}
