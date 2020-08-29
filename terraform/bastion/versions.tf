terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    dns = {
      source = "hashicorp/dns"
    }
  }
  required_version = ">= 0.13"
}
