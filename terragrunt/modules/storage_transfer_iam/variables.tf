variable "iam_prefix" {
  description = "Prefix for IAM resources"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs (including bucket and bucket/* for objects) that Storage Transfer Service needs access to"
  type        = list(string)
}


variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either \"dev\" or \"prod\"."
  }
}
