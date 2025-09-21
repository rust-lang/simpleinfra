resource "aws_iam_role" "ci" {
  name = "gha-self-hosted-images-upload"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.gh_oidc.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/gha-self-hosted:environment:upload"
          }
        }
      }
    ]
  })
}

// To ensure a build cannot affect another build, and that it's possible to rollback to previous
// builds, we allow unconditional access to override the `latest` file, and enforce that it's not
// possible to override files in the `builds/` directory.
resource "aws_iam_role_policy" "ci" {
  name = "allow-upload"
  role = aws_iam_role.ci.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.storage.arn}/latest"
      },
      {
        Effect = "Allow"
        Action = "s3:PutObject"
        Resource = [
          "${aws_s3_bucket.storage.arn}/executor/*",
          "${aws_s3_bucket.storage.arn}/images/*",
        ]
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

data "aws_iam_openid_connect_provider" "gh_oidc" {
  url = "https://token.actions.githubusercontent.com"
}
