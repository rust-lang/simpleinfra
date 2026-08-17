variable "required_dedicated_hosts" {
  description = "Approved regional M9g Dedicated Host quota required by the collector"
  type        = number

  validation {
    condition     = var.required_dedicated_hosts >= 1
    error_message = "The collector requires at least one M9g Dedicated Host."
  }
}
