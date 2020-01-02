variable "name" {
  type        = string
  description = "Name of the VPC"
}

variable "ipv4_cidr" {
  type        = string
  description = "CIDR of the IPv4 address range of the VPC"
}

variable "public_subnets" {
  type        = map(string)
  description = "Map of public subnet numbers and the associated AZ IDs"
}

variable "private_subnets" {
  type        = map(string)
  description = "Map of private subnet numbers and the associated AZ IDs"
}
