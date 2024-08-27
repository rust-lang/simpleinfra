terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
    datadog = {
      source  = "datadog/datadog"
      version = "3.43.1"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.13.0"
    }
  }
}

provider "datadog" {}
provider "fastly" {}
