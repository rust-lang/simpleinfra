terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.20"
      configuration_aliases = [aws.east1]
    }
  }
}
