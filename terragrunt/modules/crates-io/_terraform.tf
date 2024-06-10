terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.20"
      configuration_aliases = [aws.us-east-1, aws.eu-west-1]
    }
    fastly = {
      source  = "fastly/fastly"
      version = "5.0.0"
    }
  }
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

variable "static_ttl" {
  description = "TTL for static crates"
  type        = number
}

variable "static_cloudfront_weight" {
  description = "Weight of the traffic for static.crates.io that is routed through CloudFront"
  type        = number
}

variable "static_fastly_weight" {
  description = "Weight of the traffic for static.crates.io that is routed through Fastly"
  type        = number
}

variable "fastly_aws_account_id" {
  # See https://docs.fastly.com/en/guides/creating-an-aws-iam-role-for-fastly-logging
  description = "The AWS account ID that Fastly uses to write logs"
  default     = "717331877981"
}

variable "cdn_log_event_queue_arn" {
  # See the `crates-io-logs` module
  description = "ARN of the SQS queue that receives S3 notifications for CDN logs"
  type        = string
}

variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}
