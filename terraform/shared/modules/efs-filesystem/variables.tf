variable "name" {
  type        = string
  description = "Name of the EFS filesystem"
}

variable "allow_subnets" {
  type        = list(string)
  description = "List of subnet IDs allowed to interact with the EFS filesystem"
}

variable "elastic_throughput" {
  type        = bool
  description = "Whether to enable elastic throughput"
}
