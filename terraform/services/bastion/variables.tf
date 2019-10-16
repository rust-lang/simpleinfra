variable "ami_id" {
  type = string
}

variable "common_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_pair" {
  type = string
}

variable "allowed_users" {
  type = list(string)
}
