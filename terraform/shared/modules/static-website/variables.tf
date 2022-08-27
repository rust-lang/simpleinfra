variable "domain_name" {
  type        = string
  description = "Domain name of the CloudFront distribution"
}

variable "origin_domain_name" {
  type        = string
  description = "Domain name of the origin"
}

variable "origin_path" {
  type        = string
  default     = null
  description = "Root path in the origin"
}

variable "origin_access_identity" {
  type        = string
  default     = null
  description = "Origin Access Identity to use to fetch contents from S3"
}

variable "response_policy_id" {
  type        = string
  description = "CloudFront response headers policy ID"
}
