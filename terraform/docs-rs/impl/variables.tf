variable "env_name" {
  type        = string
  description = "The name of the current environment"
}

variable "ci_username" {
  type        = string
  description = "Name of the CI IAM user"
}

variable "inventories_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used to store inventories"
}
