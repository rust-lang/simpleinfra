// Variables used to configure the module, set by ../redirects.tf.

variable "from" {
  description = "List of source domains"
  type        = list(string)
}

variable "to_host" {
  description = "Destination host of the redirect"
  type        = string
}

variable "to_path" {
  description = "Destination path of the redirect"
  type        = string
  default     = ""
}

variable "permanent" {
  description = "Whether this redirect is permanent"
  type        = bool
  default     = false
}
