// IAM Role used during the execution of the application, granting all
// permissions needed at runtime.
resource "aws_iam_role" "task" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECS"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

// IAM Role used during the startup of the application, granting all
// permissions needed while creating the task.
resource "aws_iam_role" "task_execution" {
  name = "ecs-task-execution--${var.name}"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "ECS"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "task_execution" {
  role = aws_iam_role.task_execution.name
  name = "permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Access to SSM Parameter Store
      {
        Sid    = "AllowParameterStore"
        Effect = "Allow"
        Action = "ssm:GetParameters"

        Resource = concat(
          values(data.aws_ssm_parameter.task).*.arn,
          values(var.computed_secrets),
        )
      },

      // Access to CloudWatch Logs
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = "${aws_cloudwatch_log_group.task.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_ecr_pull" {
  role       = aws_iam_role.task_execution.name
  policy_arn = module.ecr.policy_pull_arn
}

data "aws_ssm_parameter" "task" {
  for_each = toset(values(var.secrets))
  name     = each.value
}