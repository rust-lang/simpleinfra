// Configuration for Terraform itself.

terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.32"
    }
  }
}

variable "users" {
  description = "The users inside the aws organization"
  type = map(object({
    given_name  = string,
    family_name = string,
    email       = string,
    groups      = list(string)
  }))
}
