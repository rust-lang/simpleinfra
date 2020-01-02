variable "name" {
  type        = string
  description = "Name of the VPC"
}

variable "ipv4_cidr" {
  type        = string
  description = "CIDR of the IPv4 address range of the VPC"
}

variable "subnets_public" {
  type        = map(string)
  description = "Map of subnet numbers and the associated AZ ID"
}
