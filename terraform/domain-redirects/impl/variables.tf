// Variables used to configure the module, set by ../redirects.tf.

variable "from" {
  description = "List of source domains"
  type        = list(string)
}

variable "to" {
  description = "Destination of the redirect"
  type        = string
}
