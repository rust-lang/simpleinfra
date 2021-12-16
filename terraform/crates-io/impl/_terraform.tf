terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.59"
      configuration_aliases = [aws.us-east-1, aws.eu-west-1]
    }
  }
}

data "aws_caller_identity" "current" {}

module "certificate" {
  source = "../../shared/modules/acm-certificate"
  providers = {
    aws = aws.us-east-1
  }

  domains = [
    var.webapp_domain_name,
    var.static_domain_name,
  ]
}

variable "webapp_domain_name" {
  type = string
}

variable "static_domain_name" {
  type = string
}

variable "static_bucket_name" {
  type = string
}

variable "inventories_bucket_arn" {
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
