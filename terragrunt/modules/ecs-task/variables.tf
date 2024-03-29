
variable "name" {
  type        = string
  description = "The name of the task"
}

variable "container_name" {
  type        = string
  description = "The name of the container being run"
}

variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}

variable "cpu" {
  type        = number
  description = "The number of CPU units used for the task"
}

variable "memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task"
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
