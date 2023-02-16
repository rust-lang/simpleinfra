// The instance profile the builder will assume when communicating with
// other AWS services.

resource "aws_iam_instance_profile" "builder" {
  name = "builder"
  role = aws_iam_role.builder.name
}

resource "aws_iam_role" "builder" {
  name = "builder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "builder_s3" {
  role = aws_iam_role.builder.name
  name = "builder_s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Access to s3
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:PutObjectTagging",
          "s3:DeleteObject"
        ]

        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })
}
