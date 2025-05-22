resource "aws_grafana_workspace" "grafana" {
  name = var.workspace_name

  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]

  // IAM roles and IAM policy attachments are generated automatically
  permission_type = "SERVICE_MANAGED"

  role_arn = aws_iam_role.assume.arn
}

resource "aws_iam_role" "assume" {
  name = "grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_grafana_role_association" "admins" {
  workspace_id = aws_grafana_workspace.grafana.id
  role         = "ADMIN"

  user_ids = ["44a894b8-d021-705c-5624-3e4485917fa0"]
}
