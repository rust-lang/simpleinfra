terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.32"
    }
    datadog = {
      source  = "datadog/datadog"
      version = "3.28.0"
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.13.0"
    }
  }
}

provider "datadog" {}
provider "fastly" {}
