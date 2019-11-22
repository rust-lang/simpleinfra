variable "caches_bucket" {
  description = "Name of the S3 bucket used for caches"
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
