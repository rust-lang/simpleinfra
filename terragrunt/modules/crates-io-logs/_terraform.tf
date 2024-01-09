terraform {
  required_version = "~> 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.32"
    }
  }
}

variable "bucket_account" {
  type        = number
  description = "Account ID of the S3 bucket which will send events to the SQS queue"
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket which will send events to the SQS queue"
}
