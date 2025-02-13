terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.86"
    }
  }
}

variable "repo" {
  description = "GitHub repository to authorize. E.g. `rust`. GitHub org is hardcoded to `rust-lang`."
  type        = string
  validation {
    condition     = !can(regex("/", var.repo))
    error_message = "The repo variable must not contain `/`. Only provide the repository name."
  }
  validation {
    condition     = length(var.repo) > 0
    error_message = "The repo variable must not be empty."
  }
}

variable "artifacts_bucket" {
  description = "ID of the existing S3 bucket to store build artifacts. If unspecified, a new bucket is created."
  type        = string
  default     = null
  validation {
    condition     = var.artifacts_bucket == null || length(var.artifacts_bucket) > 0
    error_message = "The artifacts_bucket variable must not be empty when specified."
  }
}

variable "caches_bucket" {
  description = "ID of the existing S3 bucket to store caches. If unspecified, a new bucket is created."
  type        = string
  default     = null
  validation {
    condition     = var.caches_bucket == null || length(var.caches_bucket) > 0
    error_message = "The caches_bucket variable must not be empty when specified."
  }
}
