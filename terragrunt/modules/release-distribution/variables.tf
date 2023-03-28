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

variable "log_bucket" {
  description = "Name of the bucket that stores the CloudFront logs"
  type        = string
}
