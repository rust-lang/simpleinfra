// This file contains the configuration for the rust-lang/crater's CI.

resource "aws_iam_user" "ci" {
  name = "ci--rust-lang--docs-rs"
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = aws_iam_user.ci.name
  policy_arn = var.ecr_repo.policy_push_arn
}

resource "aws_iam_user_policy_attachment" "ci_pull" {
  user       = aws_iam_user.ci.name
  policy_arn = var.ecr_repo.policy_pull_arn
}
