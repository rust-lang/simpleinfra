resource "aws_lambda_function" "image_builder" {
  source_code_hash = data.external.image_builder.result.base64sha256
  filename         = data.external.image_builder.result.path

  function_name = "gha-image-builder"
  role          = aws_iam_role.image_builder.arn
  architectures = ["arm64"]

  handler      = "index.handler"
  runtime      = "python3.13"
  package_type = "Zip"
  timeout      = 900
  memory_size  = 1024

  depends_on = [aws_cloudwatch_log_group.image_builder]
}

resource "aws_lambda_function_event_invoke_config" "image_builder" {
  function_name = aws_lambda_function.image_builder.function_name

  maximum_event_age_in_seconds = 120
  # Don't retry if AMI building fails.
  maximum_retry_attempts = 0
}

resource "aws_cloudwatch_log_group" "image_builder" {
  name              = "/aws/lambda/gha-image-builder"
  retention_in_days = 90
}

data "external" "image_builder" {
  program = ["${path.module}/../../modules/aws-lambda/pack.py"]
  query = {
    source_dir  = "${path.module}/lambda"
    destination = "/tmp/image-builder.zip"
  }
}

resource "aws_iam_role" "image_builder" {
  name = "image-builder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "image_builder" {
  name = "image-builder"
  role = aws_iam_role.image_builder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateImage",
          "ec2:DeregisterImage",
          "ebs:DeleteSnapshot",
        ]
        Resource = [
          "*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
        ]
        Resource = [
          "*",
        ]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "image_builder" {
  for_each   = toset(["aarch64", "x86_64"])
  name       = "daily-rebuild-${each.value}"
  group_name = "default"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 60
  }

  schedule_expression = "rate(1 days)"

  target {
    arn      = aws_lambda_function.image_builder.arn
    role_arn = aws_iam_role.image_invoker.arn

    input = jsonencode({
      "arch" : each.value
    })

    # Don't retry more than once. Building AMIs is relatively expensive, we don't
    # need to accidentally spin up a bunch of builders.
    retry_policy {
      maximum_retry_attempts = 1
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "image_invoker" {
  name = "image-invoker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "image_invoker" {
  name = "image-invoker"
  role = aws_iam_role.image_invoker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.image_builder.arn,
        ]
      }
    ]
  })
}
