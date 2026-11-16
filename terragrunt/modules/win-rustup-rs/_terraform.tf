terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.64"
      configuration_aliases = [aws.us-east-1]
    }
  }
}
