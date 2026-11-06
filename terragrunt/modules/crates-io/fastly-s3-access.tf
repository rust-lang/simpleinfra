resource "aws_iam_user" "fastly_s3_index_reader" {
  name = "${var.iam_prefix}-fastly-s3-index-reader"
}

resource "aws_iam_access_key" "fastly_s3_index_reader" {
  user = aws_iam_user.fastly_s3_index_reader.name
}

resource "aws_iam_user" "fastly_s3_static_reader" {
  name = "${var.iam_prefix}-fastly-s3-static-reader"
}

resource "aws_iam_access_key" "fastly_s3_static_reader" {
  user = aws_iam_user.fastly_s3_static_reader.name
}

resource "aws_iam_user_policy" "fastly_s3_static_reader" {
  name = "static-read"
  user = aws_iam_user.fastly_s3_static_reader.name

  // `s3:ListBucket` makes S3 answer requests for missing objects with
  // `404 Not Found` instead of `403 Forbidden`.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.static.arn,
          "${aws_s3_bucket.static.arn}/*",
          aws_s3_bucket.fallback.arn,
          "${aws_s3_bucket.fallback.arn}/*",
        ]
      }
    ]
  })
}
