variable "environment" {
  description = "Name of the environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment must be 'dev' or 'prod'."
  }
}

variable "doc_domain_name" {
  description = "Domain name for the doc distribution"
  type        = string
}

variable "static_domain_name" {
  description = "Domain name for the static distribution"
  type        = string
}

variable "static_bucket" {
  description = "Name of the bucket that stores the Rust releases"
  type        = string
}

variable "static_ttl" {
  description = "TTL for static assets"
  type        = number
}

variable "static_cloudfront_weight" {
  description = "Weight of the traffic for static.rust-lang.org that is routed through CloudFront"
  type        = number
}

variable "static_fastly_weight" {
  description = "Weight of the traffic for static.rust-lang.org that is routed through Fastly"
  type        = number
}

variable "log_bucket" {
  description = "Name of the bucket that stores the CloudFront logs"
  type        = string
}

variable "fastly_aws_account_id" {
  # See https://docs.fastly.com/en/guides/creating-an-aws-iam-role-for-fastly-logging
  description = "The AWS account ID that Fastly uses to write logs"
  default     = "717331877981"
}
