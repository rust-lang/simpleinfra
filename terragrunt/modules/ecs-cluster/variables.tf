variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "load_balancer_domain" {
  type        = string
  description = "The domain of the load balancer"
}

variable "zone_id" {
  type              = string
  descridescription = "The DNS zone where the load balancer DNS records should live"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC that the cluster lives in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to attach to the load balancer"
}
