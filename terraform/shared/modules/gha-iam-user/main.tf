terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = var.org
}

resource "aws_iam_user" "ci" {
  name = var.user_name != null ? var.user_name : "ci--${var.org}--${var.repo}"
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

resource "github_actions_secret" "aws_access_key_id" {
  repository      = var.repo
  secret_name     = "${var.env_prefix != null ? "${var.env_prefix}_" : ""}AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.ci.id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = var.repo
  secret_name     = "${var.env_prefix != null ? "${var.env_prefix}_" : ""}AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.ci.secret
}
