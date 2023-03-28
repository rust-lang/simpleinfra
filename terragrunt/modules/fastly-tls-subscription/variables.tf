variable "certificate_authority" {
  type        = string
  description = "The certificate authority to use"
  validation {
    condition     = contains(["lets-encrypt", "globalsign"], var.certificate_authority)
    error_message = "The certificate authority must be either 'lets-encrypt' or 'globalsign'."
  }
}

variable "domains" {
  type        = list(string)
  default     = []
  description = "The list of domains to add to the certificate"
}

variable "aws_route53_zone_id" {
  type        = string
  description = "The AWS Route53 zone in which to create the DNS records"
}

