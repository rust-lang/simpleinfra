terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.31.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "The subscription id for Azure"
  type        = string
}

variable "location" {
  description = "The Azure Region for the dev desktops"
  type        = string
}

variable "instances" {
  description = "A map of instances with their instance and disk sizes"
  type = map(object({
    instance_type = string
    storage       = number
  }))
}
