terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.59"
      configuration_aliases = [aws.east1]
    }
  }
}

