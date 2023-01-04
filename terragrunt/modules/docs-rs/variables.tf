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

variable "vpc_id" {
  type        = string
  description = "The id of the VPC in which the app lives"
}

variable "inventories_bucket_arn" {
  type        = string
  description = "The ARN of an S3 bucket to store a weekly inventories CSV dump"
  default     = ""
}
