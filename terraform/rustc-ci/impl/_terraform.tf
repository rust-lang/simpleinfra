terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.59"
      configuration_aliases = [aws.east1]
    }
  }
}

variable "caches_domain" {
  description = "Name of the domain for the cloudfront cdn in front of caches"
  type        = string
}

variable "caches_bucket" {
  description = "Name of the S3 bucket used for caches"
  type        = string
}

variable "artifacts_domain" {
  description = "Name of the domain for the cloudfront cdn in front of artifacts"
  type        = string
}

variable "artifacts_bucket" {
  description = "Name of the S3 bucket used for storing artifacts"
  type        = string
}

variable "iam_prefix" {
  description = "Prefix for all IAM resources (users, policies, roles...)"
  type        = string
}

variable "delete_artifacts_after_days" {
  description = "Number of days to delete CI artifacts after"
  type        = number
}

variable "delete_caches_after_days" {
  description = "Number of days to delete CI caches after"
  type        = number
}
