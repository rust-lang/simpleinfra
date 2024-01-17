variable "bucket_account" {
  type        = number
  description = "Account ID of the S3 bucket which will send events to the SQS queue"
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket which will send events to the SQS queue"
}
