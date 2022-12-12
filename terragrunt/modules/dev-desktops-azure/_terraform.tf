terraform {
  required_providers {
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

variable "resource_group_name" {
  description = "The name of the resource group for the dev desktops"
  type        = string
}

variable "instances" {
  description = "A map of instances with their instance and disk sizes"
  type = map(object({
    instance_type = string
    storage       = number
  }))
}
