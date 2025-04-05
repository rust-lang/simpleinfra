resource "aws_iam_role" "foo" {
  name = "ci--rust-lang--ci-mirrors"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/ci-mirrors:ref:refs/heads/gh-readonly-queue/main/*"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject"]
          Resource = "${aws_s3_bucket.rust_lang_ci_mirrors.arn}/*"
        },
      ]
    })
  }
}
