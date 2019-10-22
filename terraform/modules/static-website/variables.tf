variable "dns_zone" {
  type        = string
  description = "ID of the hosted Route53 zone containing the domain name"
}

variable "domain_name" {
  type        = string
  description = "Domain name of the CloudFront distribution"
}

variable "origin_domain_name" {
  type        = string
  description = "Domain name of the origin"
}
