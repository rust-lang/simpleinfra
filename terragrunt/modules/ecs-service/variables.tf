variable "name" {
  type        = string
  description = "Name of the service to create"
}

variable "platform_version" {
  type        = string
  description = "The fargate version to use"
}

variable "task_arn" {
  type        = string
  description = "ARN of the task to spawn in the service"
}

variable "tasks_count" {
  type        = string
  description = "Number of copies of the task to spawn, balanced across AZs"
}

variable "http_container" {
  type        = string
  description = "Name of the container inside the task serving HTTP"
}

variable "http_port" {
  type        = string
  description = "Name of the port where the container serves HTTP"
}

variable "domains" {
  type        = list(string)
  description = "List of domain names the load balancer will forward to the container"
}

variable "zone_id" {
  type        = string
  description = "The id of the DNS zone where domain records are stored"
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
  description = "Shared configuration of the ECS cluster"
}

variable "deployment_minimum_healty_percent" {
  type    = number
  default = 100
}

variable "deployment_maximum_percent" {
  type    = number
  default = 200
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_interval" {
  type    = string
  default = 30
}

variable "health_check_timeout" {
  type    = number
  default = 5
}
