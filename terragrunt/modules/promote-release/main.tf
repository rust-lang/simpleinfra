terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.54"
      configuration_aliases = [aws.us-east-2]
    }
  }
}
