terraform {
  required_version = ">= 1.1.5, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61"
    }
    datadog = {
      source  = "datadog/datadog"
      version = "4.1.0"
    }
  }
}

provider "datadog" {}
