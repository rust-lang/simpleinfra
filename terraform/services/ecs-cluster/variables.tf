variable "cluster_name" {
  type = string
}

variable "load_balancer_domain" {
  type = string
}

variable "load_balancer_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "dns_zone" {
  type = string
}
