variable "name" {
  type        = string
  description = "Name of the task"
}

variable "cpu" {
  type        = number
  description = "CPU quota allocated to the task. 1024 represents a full virtual core."
}

variable "memory" {
  type        = number
  description = "Amount of RAM allocated to the task, in megabytes."
}

variable "containers" {
  type        = string
  description = <<EOD
    JSON-encoded list of container definitions.
    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
  EOD
}

variable "volumes" {
  type = list(object({
    name           = string
    file_system_id = string
    iam            = bool
  }))

  description = "Optional EFS volumes"
  default     = null
}

variable "log_retention_days" {
  type        = number
  description = "After how many days should CloudWatch purge the logs"
}

variable "ecr_repositories_arns" {
  type        = list(string)
  description = "List of ECR repository ARNs this task is allowed to pull"
}

variable "task_role_arn" {
  type        = string
  default     = null
  description = "The ARN of the task role"
}
