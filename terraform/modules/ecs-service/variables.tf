variable "name" {
  type        = string
  description = "Name of the service to create"
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

variable "cluster_config" {
  type = object({
    cluster_id                = string,
    lb_listener_arn           = string,
    lb_dns_name               = string,
    service_security_group_id = string,
    subnet_ids                = list(string),
    vpc_id                    = string,
  })
  description = "Shared configuration of the ECS cluster"
}
