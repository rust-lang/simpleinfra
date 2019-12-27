// This file defines an IAM role called "ecs-task-execution--${var.name}",
// which is used by ECS to start the containers included in the current task.
//
// The role has the following permissions:
// - Download images from the whitelisted ECR repository.
// - Upload logs to this task's CloudWatch destination.
// - Access the SSM parameters in the /prod/ecs/${var.name} namespace.

resource "aws_iam_policy" "task_execution" {
  name   = "ecs-task-execution--${var.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowParameterStore",
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/prod/ecs/${var.name}/*"
      ]
    },
    {
      "Sid": "AllowLogs",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ],
      "Resource": "${aws_cloudwatch_log_group.task.arn}"
    },
    {
      "Sid": "AllowContainersDownload",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": ${jsonencode(var.ecr_repositories_arns)}
    },
    {
      "Sid": "ECRAuthentication",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "task_execution" {
  name               = "ecs-task-execution--${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "EcsTasks",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution.arn
}
