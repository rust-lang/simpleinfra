variable "domain_name" {
  type        = string
  description = "Domain name hosting the triagebot application"
}

variable "dns_zone" {
  type        = string
  description = "DNS zone hosting the domain name"
}

variable "cluster_config" {
  type = object({
    cluster_id                = string,
    lb_listener_arn           = string,
    lb_dns_name               = string,
    service_security_group_id = string,
    subnet_ids                = list(string),
    vpc_id                    = string,
  })
  description = "Shared configuration of the ECS cluster"
}
