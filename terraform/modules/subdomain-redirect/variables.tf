variable "from" {
  description = "Map of source domains, with Route53 Zone IDs as values"
  type = map(string)
}

variable "to" {
  description = "Destination of the redirect"
  type = string
}
