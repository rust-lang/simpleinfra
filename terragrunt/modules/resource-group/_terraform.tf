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

variable "resource_group_name" {
  description = "The name of the resource group for the dev desktops"
  type        = string
}
