resource "aws_s3_bucket" "downloads_archive" {
  provider = aws.us-east-1

  bucket = var.downloads_archive_bucket_name
}

data "aws_iam_user" "heroku_access" {
  user_name = "crates-io-heroku-access"
}

resource "aws_iam_user_policy" "downloads_archive_write" {
  name   = "downloads-archive-write"
  user   = data.aws_iam_user.heroku_access.user_name
  policy = data.aws_iam_policy_document.downloads_archive_write.json
}

data "aws_iam_policy_document" "downloads_archive_write" {
  statement {
    sid    = "WriteToDownloadsArchive"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [aws_s3_bucket.downloads_archive.arn]
  }
}
