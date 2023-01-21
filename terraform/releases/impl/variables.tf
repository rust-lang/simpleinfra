variable "name" {
  type = string
}

variable "bucket" {
  type = string
}

variable "inventories_bucket_arn" {
  type = string
}

variable "static_domain_name" {
  type = string
}

variable "doc_domain_name" {
  type = string
}

variable "release_keys_bucket_arn" {
  type = string
}

variable "promote_release_ecr_repo" {
  type = object({
    arn             = string
    url             = string
    policy_push_arn = string
    policy_pull_arn = string
  })
}

variable "promote_release_cron" {
  type = map(string)
}

variable "log_bucket" {
  type = string
}
