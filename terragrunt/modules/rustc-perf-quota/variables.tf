variable "dedicated_host_limit" {
  description = "Regional Running Dedicated m9g Hosts quota to request"
  type        = number

  validation {
    condition     = var.dedicated_host_limit >= 1
    error_message = "The quota must allow at least one M9g Dedicated Host."
  }
}
