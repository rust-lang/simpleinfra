variable "webapp_domain_name" {
  type = string
}

variable "static_domain_name" {
  type = string
}

variable "static_bucket_name" {
  type = string
}

variable "inventories_bucket_arn" {
  type = string
}

variable "webapp_origin_domain" {
  type = string
}

variable "iam_prefix" {
  type = string
}

variable "dns_apex" {
  type    = bool
  default = false
}

variable "logs_bucket" {
  description = "If this is set, URL of the bucket to store access logs into."
  type        = string
  default     = null
}
