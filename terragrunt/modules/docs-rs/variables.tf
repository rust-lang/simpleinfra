variable "zone_id" {
  type        = string
  description = "The DNS zone where the DNS records should live"
}

variable "domain" {
  type        = string
  description = "The domain of the docs.rs instance"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet ids"
}

variable "bastion_security_group_id" {
  type        = string
  description = "Id of the security group for the bastion instance"
}

variable "cluster_config" {
  type = object({
    cluster_id                = string,
    lb_listener_arn           = string,
    lb_domain                 = string
    service_security_group_id = string,
    subnet_ids                = list(string),
    vpc_id                    = string,
  })
  description = "The configuration for the cluster this is running in"
}

variable "min_num_builder_instances" {
  type        = number
  description = "The minimum number of builder instances there should be"
}

variable "max_num_builder_instances" {
  type        = number
  description = "The maximum number of builder instances there should be"
}
