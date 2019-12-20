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
