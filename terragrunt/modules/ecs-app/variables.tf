variable "name" {
  type = string
}

variable "repo" {
  type = string
}

variable "github_environment" {
  type        = string
  description = "GitHub environment used to upload the ECR container image. If specified, you can use GitHub Actions OIDC to upload the Docker ECR image."
  default     = null
}

variable "gh_oidc_arn" {
  type        = string
  description = "ARN of a GitHub Actions OIDC provider to use when creating the CI role."
  default     = null
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
    service_security_group_id = string,
    subnet_ids                = list(string),
    vpc_id                    = string,
  })
}
