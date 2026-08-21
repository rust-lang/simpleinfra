variable "datadog_api_key_secret_name" {
  description = "Name of the Secrets Manager secret containing the Datadog API key used by the Forwarder"
  type        = string

  validation {
    condition     = length(var.datadog_api_key_secret_name) > 0
    error_message = "The Datadog API key secret name must not be empty."
  }
}
