terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.27"
      configuration_aliases = [aws.us-east-1]
    }
  }
}
