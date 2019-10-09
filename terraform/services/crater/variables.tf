variable "ecr_repo" {
  type = object({
    policy_push_arn = string
    policy_pull_arn = string
  })
}
