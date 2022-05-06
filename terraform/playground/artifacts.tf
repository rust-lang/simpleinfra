// Storage for the artifacts built by the playground's CI, which will be
// accessed by the instance(s) for deployment.

resource "aws_s3_bucket" "artifacts" {
  bucket = "rust-playground-artifacts"
  acl    = "private"

  lifecycle_rule {
    id      = "incomplete-uploads"
    enabled = true

    abort_incomplete_multipart_upload_days = 1
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "upload_artifacts" {
  name = "upload-playground-artifacts"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = data.terraform_remote_state.shared.outputs.gha_oidc_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:integer32llc/rust-playground:ref:refs/heads/master"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "upload"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "s3:ListBucket"
          Resource = aws_s3_bucket.artifacts.arn
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          ]
          Resource = "${aws_s3_bucket.artifacts.arn}/*"
        },
      ]
    })
  }
}
