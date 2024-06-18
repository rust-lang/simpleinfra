# The rust-lang/rustup repository on GitHub builds and uploads Rustup artifacts
# to this S3 bucket.
resource "aws_s3_bucket" "builds" {
  provider = aws.us-east-1

  bucket = "rustup-builds"
}

module "aws_iam_user" {
  source = "../gha-iam-user"
  org    = "rust-lang"
  repo   = "rustup"
}

data "aws_iam_policy_document" "upload_builds" {
  statement {
    sid    = "WriteToRustupBuilds"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.builds.arn}/*"]
  }
}

resource "aws_iam_user_policy" "upload_builds" {
  name   = "upload-rustup-builds"
  user   = module.aws_iam_user.user_name
  policy = data.aws_iam_policy_document.upload_builds.json
}
