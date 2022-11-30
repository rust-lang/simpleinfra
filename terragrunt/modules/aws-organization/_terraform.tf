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

provider "aws" {
  region = "us-east-1"
}

variable "users" {
  description = "The users inside the aws organization"
  type = map(object({
    given_name  = string,
    family_name = string,
    email       = string,
    groups      = list(string)
  }))

  validation {
    condition = alltrue([
      for name, user in var.users : alltrue([for group in user.groups : contains(["infra", "infra-admins"], group)])
    ])
    error_message = "The only valid group names are \"infra\" or \"infra-admins\""
  }
}
