variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}

variable "datadog_forwarder_arns" {
  description = "ARNs of Datadog Forwarder Lambda functions registered for automatic log subscription"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.datadog_forwarder_arns : length(trimspace(arn)) > 0])
    error_message = "Datadog Forwarder ARNs must be non-empty strings."
  }
}

variable "datadog_log_sources" {
  description = "AWS log sources for which Datadog should configure automatic Forwarder subscriptions"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for source in var.datadog_log_sources : length(trimspace(source)) > 0])
    error_message = "Datadog log sources must be non-empty strings."
  }
}
