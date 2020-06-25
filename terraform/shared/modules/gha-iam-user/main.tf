provider "github" {
  organization = var.org
}

resource "aws_iam_user" "ci" {
  name = "ci--${var.org}--${var.repo}"
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

resource "github_actions_secret" "aws_access_key_id" {
  repository      = var.repo
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.ci.id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = var.repo
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.ci.secret
}
