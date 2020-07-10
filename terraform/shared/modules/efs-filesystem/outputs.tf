output "id" {
  value = aws_efs_file_system.efs.id
}

output "arn" {
  value = aws_efs_file_system.efs.arn
}

output "root_policy_arn" {
  value = aws_iam_policy.efs_root.arn
}
