variable "repository" {
  type        = string
  description = "The GitHub repository where the codebuild project will be used."
  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.repository))
    error_message = "The repository must be in the format 'owner/repo'."
  }
}

variable "code_connection_name" {
  type        = string
  description = "The name of the code connection that will be created to connect the codebuild projects to GitHub."
}

variable "executor_account_id" {
  type        = string
  description = "The ID of the AWS account that will manage EC2 instances in this account"
}
