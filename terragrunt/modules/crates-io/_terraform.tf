terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.20"
      configuration_aliases = [aws.us-east-1, aws.eu-west-1]
    }
    fastly = {
      source  = "fastly/fastly"
      version = "3.0.0"
    }
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

provider "fastly" {}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
}

locals {
  inventories_bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
}

variable "webapp_domain_name" {
  type = string
}

variable "static_domain_name" {
  type = string
}

variable "index_domain_name" {
  type = string
}

variable "static_bucket_name" {
  type = string
}

variable "index_bucket_name" {
  type = string
}

variable "webapp_origin_domain" {
  type = string
}

variable "iam_prefix" {
  type = string
}

variable "dns_apex" {
  type    = bool
  default = false
}

variable "strict_security_headers" {
  type    = bool
  default = false
}
