resource "aws_iam_role" "clippy_artifacts" {
  name = "clippy-ci--rust-lang--clippy-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::890664054962:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/rust-clippy:ref:refs/heads/automation/bors/try"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "clippy_artifacts" {
  name = "put-objects"
  role = aws_iam_role.clippy_artifacts.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ArtifactsBucketWrite"
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/clippy-builds/$${aws:TransactionContext/IdentityProvider/github-sha}/*",
        ]
        Action = [
          "s3:PutObject",
        ]
        Condition = {
          StringLike = {
            // Requires that the github sha be the right length to be a SHA-1
            // hash. This will need updating to support SHA-256 hashes (which
            // are longer), but we don't currently have those.
            "aws:TransactionContext/IdentityProvider/github-sha" = "????????????????????????????????????????"
          }
        }
      },
      {
        Sid      = "HeadBuckets",
        Effect   = "Allow",
        Resource = "*"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
        ],
      },
    ]
  })
}
