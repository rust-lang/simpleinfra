terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.31.0"
    }
  }
}

variable "location" {
  description = "The Azure Region for the dev desktops"
  type        = string
}

variable "instances" {
  type = map(object({
    instance_type = string
    storage       = number
  }))
}
