variable "source_dir" {
  description = "Path to the Lambda source directory to package (folder containing bootstrap)"
  type        = string
}

variable "destination" {
  description = "Path to output the packaged zip file"
  type        = string
}

variable "name" {
  description = "Name of the lambda function"
  type        = string
}

variable "environment" {
  description = "Map of environment variables to set in the Lambda"
  type        = map(string)
  default     = {}
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function, in seconds"
  type        = number
  default     = 30
}
