output "arn" {
  value       = aws_ecr_repository.repo.arn
  description = "The ARN of the ECR repository created by this module."
}

output "policy_push_arn" {
  value       = aws_iam_policy.push.arn
  description = "The ARN of the IAM policy allowed to push to this repository."
}

output "policy_pull_arn" {
  value       = aws_iam_policy.pull.arn
  description = "The ARN of the IAM policy allowed to pull from this repository."
}
