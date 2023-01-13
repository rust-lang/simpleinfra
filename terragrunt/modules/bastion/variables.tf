variable "allowed_users" {
  description = "Users allowed to connect to the bastion through SSH. Each user needs to have the CIDR of the static IP they want to connect from stored in AWS SSM Parameter Store, in a string key named: /prod/bastion/allowed-ips/$user"
  type        = list(string)
}

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
