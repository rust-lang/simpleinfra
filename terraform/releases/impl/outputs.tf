output "promote_release_role_id" {
  value = aws_iam_role.promote_release.unique_id
}

output "codebuild_project_arn" {
  value = aws_codebuild_project.promote_release.arn
}
