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
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/ci-mirrors:environment:upload"
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
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.rust_lang_ci_mirrors.arn}/*"
        },
        {
          Effect   = "Allow"
          Action   = "s3:PutObject"
          Resource = "${aws_s3_bucket.rust_lang_ci_mirrors.arn}/*"
          Condition = {
            StringEquals = {
              // Enforce that the `if-none-match: *` header is provided when uploading a new file,
              // ensuring CI can never override an existing file.
              "s3:if-none-match" = "*"
            }
          }
        },
      ]
    })
  }
}
