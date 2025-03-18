variable "name" {
  type        = string
  description = "The name of the project. What you need to write in the yaml GitHub Actions workflow."
}

variable "service_role" {
  type        = string
  description = "The IAM role that AWS CodeBuild assumes to run the build."
}

variable "compute_type" {
  type        = string
  description = "Instance type."
}

variable "repository" {
  type        = string
  description = "The GitHub repository where the codebuild project will be used."
  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.repository))
    error_message = "The repository must be in the format 'owner/repo'."
  }
}
