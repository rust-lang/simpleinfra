data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "runtime" {
  name = "bors-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ssm" {
  role       = aws_iam_role.runtime.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ecr" {
  role       = aws_iam_role.runtime.name
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
}

resource "aws_iam_policy" "ssm_access" {
  name        = "ecs_ssm_access"
  path        = "/"
  description = "Access to SSM secrets for ECS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ssm:GetParameters"
        Effect = "Allow"
        Resource = [
          data.aws_ssm_parameter.app_key.arn,
          data.aws_ssm_parameter.webhook_secret.arn,
          aws_ssm_parameter.db_endpoint.arn,
          data.aws_ssm_parameter.oauth_client_secret.arn,
          data.aws_ssm_parameter.zulip_token.arn,
        ]
      }
    ]

  })
}

resource "aws_iam_role_policy" "gha-self-hosted" {
  name = "gha-self-hosted"
  role = aws_iam_role.runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Resource = [
          // Allow assuming roles in both the staging and prod accounts.
          // We allow both because it may be useful for prod to launch a subset
          // of instances in staging (for verification that rust-lang/rust
          // runners will work against changes to infrastructure).
          //
          // Note that right now only the corresponding target account actually
          // allows access from bors.
          "arn:aws:iam::442426873467:role/*",
          "arn:aws:iam::008376430877:role/*",
        ]
      }
    ]
  })
}
