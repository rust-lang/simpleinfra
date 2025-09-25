variable "project_id" {
  description = "GCP project ID for the backup"
  type        = string
}

variable "region" {
  description = "GCP region for the backup"
  type        = string
}

variable "source_buckets" {
  description = "Map of source AWS S3 buckets to backup"
  type = map(object({
    bucket_name   = string
    cloudfront_id = string
    description   = string
    # ID of the AWS access key that Google Storage Transfer uses to authenticate for AWS S3 access
    aws_access_key_id = string
  }))
}

variable "environment" {
  description = "Environment (prod or dev)"
  type        = string
  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "Environment must be either 'prod' or 'dev'."
  }
}

# variable "admins" {
#   description = "List of email addresses of users with admin access"
#   type        = list(string)
# }

# variable "viewers" {
#   description = "List of email addresses of users with read-only access"
#   type        = list(string)
# }
