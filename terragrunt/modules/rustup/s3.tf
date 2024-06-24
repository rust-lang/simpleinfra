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
  branch = "master"
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
