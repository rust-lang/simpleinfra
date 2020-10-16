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
  configuration {
    url          = "https://${var.domain_name}/github"
    secret       = random_password.webhook_secrets[each.key].result
    content_type = "json"
    insecure_ssl = false
  }

  events = [
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
