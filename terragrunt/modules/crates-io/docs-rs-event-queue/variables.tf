variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}

variable "producer_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs allowed to publish events to the queue."

  validation {
    condition     = length(var.producer_principal_arns) > 0
    error_message = "At least one producer principal ARN must be provided."
  }
}

variable "consumer_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs allowed to consume events from the queue."

  validation {
    condition     = length(var.consumer_principal_arns) > 0
    error_message = "At least one consumer principal ARN must be provided."
  }
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "The queue visibility timeout in seconds."
  default     = 300
}

variable "backlog_warning_threshold" {
  type        = number
  description = "Warn when the visible message backlog is above this number."
  default     = 25
}

variable "backlog_critical_threshold" {
  type        = number
  description = "Alert when the visible message backlog is above this number."
  default     = 100
}

variable "oldest_message_age_warning_seconds" {
  type        = number
  description = "Warn when the oldest visible message is older than this many seconds."
  default     = 300
}

variable "oldest_message_age_critical_seconds" {
  type        = number
  description = "Alert when the oldest visible message is older than this many seconds."
  default     = 900
}
