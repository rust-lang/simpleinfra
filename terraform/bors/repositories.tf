locals {
  webhook_url  = "https://${var.domain_name}/github"
  webhook_type = "json"

  webhook_events = [
    "check_run",
    "commit_comment",
    "issue_comment",
    "issues",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
    "push",
    "status",
  ]
}

resource "random_password" "webhook_secrets" {
  for_each = var.repositories

  length  = 32
  special = false
}

resource "aws_ssm_parameter" "webhook_secrets" {
  for_each = var.repositories

  name  = "/prod/ecs/bors/webhook-secrets/${each.key}"
  type  = "SecureString"
  value = random_password.webhook_secrets[each.key].result
}

resource "github_repository_webhook" "bors" {
  for_each = var.repositories

  active     = true
  repository = each.value
  events     = local.webhook_events
  configuration {
    url          = local.webhook_url
    secret       = random_password.webhook_secrets[each.key].result
    content_type = local.webhook_type
    insecure_ssl = false
  }
}

resource "github_repository_webhook" "bors__rust_lang_ci__rust" {
  provider = github.rust_lang_ci

  active     = true
  repository = "rust"
  events     = local.webhook_events
  configuration {
    url          = local.webhook_url
    secret       = random_password.webhook_secrets["rust"].result
    content_type = local.webhook_type
    insecure_ssl = false
  }
}
