terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.17"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "project" {
  description = "The GCP project for the dev desktops"
  type        = string
}

variable "region" {
  description = "The GCP region for the dev desktops"
  type        = string
}

variable "zone" {
  description = "The GCP zone for the dev desktops"
  type        = string
}

# A dedicated network keeps dev-desktop traffic isolated from other services.
variable "network_name" {
  description = "The VPC network name for dev desktops"
  type        = string
  default     = "dev-desktops"
}

variable "subnet_cidr" {
  description = "The IPv4 CIDR range for the dev desktops subnet"
  type        = string
  # the default is a small range, since the dev
  # desktops fleet is expected to remain small
  default = "10.40.0.0/24"
}

# Instances are keyed by hostname to keep DNS/monitoring aligned with names.
variable "instances" {
  description = "A map of instances with their machine types and disk sizes"
  type = map(object({
    instance_type = string
    storage       = number
  }))
}
