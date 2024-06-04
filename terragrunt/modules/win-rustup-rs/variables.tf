variable "domain_name" {
  description = "The domain name for the CloudFront distribution"
  type        = string
}

variable "static_bucket" {
  description = "Name of the bucket that stores the Rustup releases"
  type        = string
}
