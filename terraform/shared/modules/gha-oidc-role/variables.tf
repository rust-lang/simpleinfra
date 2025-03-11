variable "org" {
  type        = string
  description = "The GitHub organization where the repository lives"
}

variable "repo" {
  type        = string
  description = "The name of the repository inside the organization"
}

variable "branch" {
  type        = string
  description = "The branch of the repository allowed to assume the role"
  default     = null
}

variable "environment" {
  type        = string
  description = "The GitHub environment allowed to assume the role"
  default     = null
}
