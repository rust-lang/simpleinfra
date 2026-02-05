variable "vpc_id" {
  type        = string
  description = "The id of the VPC this bastion is running in"
}

variable "public_subnet_id" {
  type        = string
  description = "The id of the public subnet where the bastion instance lives"
}

variable "zone_id" {
  type        = string
  description = "The id for the zone where DNS records live"
}
