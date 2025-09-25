# This module configures the IAM user and policies for Google Storage Transfer Service.
# see https://cloud.google.com/storage-transfer/docs/s3-cloudfront.

# IAM user for Google Storage Transfer Service
resource "aws_iam_user" "storage_transfer" {
  name = "${var.iam_prefix}--storage-transfer"
}

resource "aws_iam_policy" "storage_transfer_read" {
  name        = "${var.iam_prefix}--storage-transfer-read"
  description = "Read access to S3 buckets for Google Storage Transfer Service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion",
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "storage_transfer_read" {
  user       = aws_iam_user.storage_transfer.name
  policy_arn = aws_iam_policy.storage_transfer_read.arn
}

resource "aws_iam_access_key" "storage_transfer" {
  user = aws_iam_user.storage_transfer.name
}
