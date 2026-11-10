
variable "name" {
  type        = string
  description = "The name of the task"
}

variable "container_name" {
  type        = string
  description = "The name of the container being run"
}

variable "command" {
  type        = list(string)
  default     = null
  description = "Override the image's default command; null keeps the image default."
}



variable "cpu" {
  type        = number
  description = "Total CPU units for the task, including any Datadog sidecars."
  validation {
    condition     = var.cpu > 0 && floor(var.cpu) == var.cpu
    error_message = "Task CPU units must be a positive integer."
  }
}

variable "memory" {
  type        = number
  description = "Total memory in MiB for the task, including any Datadog sidecars."
  validation {
    condition     = var.memory > 0 && floor(var.memory) == var.memory
    error_message = "Task memory must be a positive integer in MiB."
  }
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "A map of environment variable names to their values"
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "Keys of secrets stored in Parameter Store to expose to your container"
  validation {
    condition     = !contains([for key, value in var.secrets : value if substr(value, 0, 4) != "arn:"], false)
    error_message = "Computed secrets must not be ARNs."
  }
}

variable "computed_secrets" {
  type        = map(string)
  default     = {}
  description = "ARNs of secrets stored in Parameter Store to expose to your container"
  validation {
    condition     = !contains([for key, value in var.computed_secrets : value if substr(value, 0, 4) == "arn:"], false)
    error_message = "Computed secrets must be ARNs."
  }
}

variable "port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  description = "Mappings between port in container and on the host"
}

variable "docker_labels" {
  type        = map(string)
  default     = {}
  description = "A key/value map of labels to add to the container"
}

variable "ephemeral_storage_gb" {
  type        = number
  default     = 21
  description = "The amount of ephemeral storage (in GiB) to allocate for the task"
}

variable "datadog" {
  description = "Optional Fargate Agent (task metrics and OTLP/gRPC) and FireLens logging. The API key must be an SSM parameter; use the AWS-managed SSM key or separately grant kms:Decrypt. Sidecar resources are reserved from the total task CPU and memory."
  type = object({
    api_key_parameter_arn = string
    environment           = string
  })
  default = null

  validation {
    condition = var.datadog == null ? true : (
      can(regex("^arn:[^:]+:ssm:[^:]+:[0-9]{12}:parameter/.+", var.datadog.api_key_parameter_arn)) &&
      length(trimspace(var.datadog.environment)) > 0
    )
    error_message = "Datadog requires an SSM parameter ARN and a nonempty environment."
  }
}
