# assume the required IAM role for Lambda functions and retrieve a set of temporary
# credentials to access the AWS platform.
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Basic execution role for Lambda to write logs
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 permissions for listing objects in staging-crates-io bucket
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::staging-crates-io"
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.name}-s3-access-policy"
  description = "IAM policy for S3 access from Lambda function"
  policy      = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.s3_access.arn
}
