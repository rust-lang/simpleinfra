# The rust-lang/rustup repository on GitHub builds and uploads Rustup artifacts
# to this S3 bucket.
resource "aws_s3_bucket" "builds" {
  provider = aws.us-east-1

  bucket = "rustup-builds"
}

module "ci_role" {
  source = "../gha-oidc-role"
  org    = "rust-lang"
  repo   = "rustup"
  branch = "main"
}

resource "aws_s3_bucket_policy" "cloudfront" {
  provider = aws.us-east-1

  bucket = aws_s3_bucket.builds.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnlyAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.builds.arn}/*"]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.builds.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "upload_builds" {
  name = "upload-rustup-builds"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteToRustupBuilds"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.builds.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ci_upload_builds" {
  role       = module.ci_role.role.id
  policy_arn = aws_iam_policy.upload_builds.arn
}
