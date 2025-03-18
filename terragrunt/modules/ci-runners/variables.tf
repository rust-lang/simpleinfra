// Since you can't create the connection from the terraform provider (as of Dec 2024),
// you need to create the connection manually at
// https://us-east-2.console.aws.amazon.com/codesuite/settings/connections
variable "code_connection_arn" {
  description = "Arn of the GitHub CodeConnection for the GitHub organization."
}

variable "repository" {
  type        = string
  description = "The GitHub repository where the codebuild project will be used."
  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.repository))
    error_message = "The repository must be in the format 'owner/repo'."
  }
}
