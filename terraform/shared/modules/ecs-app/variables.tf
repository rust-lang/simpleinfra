variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "The environment must be 'dev' or 'prod'."
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

variable "mount_efs" {
  type    = string
  default = null
}

variable "expose_http" {
  type = object({
    container_port = number
    domains        = list(string)

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
