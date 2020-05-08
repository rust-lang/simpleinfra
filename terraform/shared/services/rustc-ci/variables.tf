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
