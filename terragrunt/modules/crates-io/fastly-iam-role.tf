data "aws_ssm_parameter" "fastly_customer_id" {
  name = var.fastly_customer_id_ssm_parameter
}

resource "aws_iam_role" "fastly_assume_role" {
  name        = "${var.iam_prefix}--fastly"
  description = "Allow Fastly to assume a role with write access to the logs for ${var.webapp_domain_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Condition = {
          StringEquals = {
            "sts:ExternalId" = [
              data.aws_ssm_parameter.fastly_customer_id.value
            ]
          }
        }
        Action = "sts:AssumeRole"
        Principal = {
          AWS = var.fastly_aws_account_id
        }
        Effect = "Allow"
        Sid    = "S3LoggingTrustPolicy"
      },
    ]
  })
}

resource "aws_iam_policy" "fastly_put_logs" {
  name        = "${var.iam_prefix}--fastly-put-logs"
  description = "Allow Fastly to put the logs for ${var.webapp_domain_name} into S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.logs.arn}/*"
    }]
  })
}

resource "aws_iam_policy_attachment" "fastly_s3_logging" {
  name = "${var.iam_prefix}--fastly-s3-logging"

  roles      = [aws_iam_role.fastly_assume_role.name]
  policy_arn = aws_iam_policy.fastly_put_logs.arn
}
