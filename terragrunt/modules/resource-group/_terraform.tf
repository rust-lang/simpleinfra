terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0.1"
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
