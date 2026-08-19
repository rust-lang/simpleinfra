terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    datadog = {
      source  = "datadog/datadog"
      version = "3.91.0"
    }
  }
}

provider "datadog" {}
