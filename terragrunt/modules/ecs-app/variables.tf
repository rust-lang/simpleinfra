variable "env" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.env)
    error_message = "The environment must be 'staging' or 'prod'."
  }
}

variable "name" {
  type = string
}

variable "repo" {
  type = string
}

variable "platform_version" {
  type = string
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "tasks_count" {
  type = number
}

variable "ephemeral_storage_gb" {
  type    = number
  default = 21
}

variable "expose_http" {
  type = object({
    container_port = number
    prometheus     = string
    domains        = list(string)
    zone_id        = string

    health_check_path     = string
    health_check_interval = number
    health_check_timeout  = number
  })
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  type    = map(string)
  default = {}
  validation {
    condition     = !contains([for key, value in var.secrets : value if substr(value, 0, 4) != "arn:"], false)
    error_message = "Computed secrets must not be ARNs."
  }
}

variable "computed_secrets" {
  type    = map(string)
  default = {}
  validation {
    condition     = !contains([for key, value in var.computed_secrets : value if substr(value, 0, 4) == "arn:"], false)
    error_message = "Computed secrets must be ARNs."
  }
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of additional security groups to add to the service"
}

variable "cluster_config" {
  type = object({
    cluster_id                = string,
    lb_listener_arn           = string,
    lb_dns_name               = string,
    service_security_group_id = string,
    subnet_ids                = list(string),
    vpc_id                    = string,
  })
}
