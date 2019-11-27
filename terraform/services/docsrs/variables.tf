variable "ecr_repo" {
  type = object({
    policy_push_arn = string
    policy_pull_arn = string
  })
}

variable "storage_bucket" {
  type = string
}

variable "backups_bucket" {
  type = string
}
