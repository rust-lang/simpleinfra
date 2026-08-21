variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}

variable "cloudtrail_datadog_api_key_secret_name" {
  description = "Name of the Secrets Manager secret used by the CloudTrail Forwarder; null disables the organization trail"
  type        = string
  default     = null

  validation {
    condition     = var.cloudtrail_datadog_api_key_secret_name == null ? true : length(trimspace(var.cloudtrail_datadog_api_key_secret_name)) > 0
    error_message = "The CloudTrail Datadog API key secret name must be null or a non-empty string."
  }
}
