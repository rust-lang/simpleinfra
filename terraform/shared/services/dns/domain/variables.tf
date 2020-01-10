variable "domain" {
  type = string
}

variable "comment" {
  type = string
}

variable "ttl" {
  type = number
}

variable "A" {
  type    = map(list(string))
  default = {}
}

variable "CNAME" {
  type    = map(list(string))
  default = {}
}

variable "MX" {
  type    = map(list(string))
  default = {}
}

variable "TXT" {
  type    = map(list(string))
  default = {}
}
