variable "domain_name" {
  type        = string
  description = "Domain name of the CloudFront distribution"
}

variable "origin_domain_name" {
  type        = string
  description = "Domain name of the origin"
}

variable "origin_access_identity" {
  type        = string
  default     = null
  description = "Origin Access Identity to use to fetch contents from S3"
}
