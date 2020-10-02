variable "name" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "timeout_seconds" {
  type    = number
  default = 3
}
