terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.86"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.2"
    }
  }
}

provider "github" {
  owner = "rust-lang"
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
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
  description = "ID of the S3 bucket to store build artifacts. If unspecified, it is automatically generated, based on the repo name."
  type        = string
  default     = null
  validation {
    condition     = var.artifacts_bucket == null ? true : length(var.artifacts_bucket) > 0
    error_message = "The artifacts_bucket variable must not be empty when specified."
  }
}

variable "inventories_bucket" {
  description = "ID of the S3 bucket to store rust inventories. If unspecified, it is automatically generated, based on the repo name."
  type        = string
  default     = null
  validation {
    condition     = var.inventories_bucket == null ? true : length(var.inventories_bucket) > 0
    error_message = "The inventories_bucket variable must not be empty when specified."
  }
}

variable "caches_bucket" {
  description = "ID of the S3 bucket to store caches. If unspecified, it is automatically generated, based on the repo name."
  type        = string
  default     = null
  validation {
    condition     = var.caches_bucket == null ? true : length(var.caches_bucket) > 0
    error_message = "The caches_bucket variable must not be empty when specified."
  }
}

variable "artifacts_domain" {
  description = "Domain name for the CloudFront distribution in front of the artifacts bucket. If unspecified, it is automatically generated, based on the repo name."
  type        = string
  default     = null
  validation {
    condition     = var.artifacts_domain == null ? true : length(var.artifacts_domain) > 0
    error_message = "The artifacts_domain variable must not be empty when specified."
  }
}

variable "caches_domain" {
  description = "Domain name for the CloudFront distribution in front of the caches bucket. If unspecified, it is automatically generated, based on the repo name."
  type        = string
  default     = null
  validation {
    condition     = var.caches_domain == null ? true : length(var.caches_domain) > 0
    error_message = "The caches_domain variable must not be empty when specified."
  }
}
