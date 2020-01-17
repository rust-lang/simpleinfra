variable "from" {
  description = "List of source domains"
  type        = list(string)
}

variable "to" {
  description = "Destination of the redirect"
  type        = string
}
