terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.86"
    }
  }
}

variable "repo" {
  description = "GitHub repository to authorize. E.g. `rust`. GitHub org is hardcoded to `rust-lang`."
  type        = string
  validation {
    condition     = !can(regex("/", var.repo))
    error_message = "The repo variable must not contain `/`. Only provide the repository name."
  }
  validation {
    condition     = length(var.repo) > 0
    error_message = "The repo variable must not be empty."
  }
}
