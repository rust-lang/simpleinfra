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
    bucket_name       = string
    cloudfront_domain = string
    description       = string
  }))
}

# variable "admins" {
#   description = "List of email addresses of users with admin access"
#   type        = list(string)
# }

# variable "viewers" {
#   description = "List of email addresses of users with read-only access"
#   type        = list(string)
# }
