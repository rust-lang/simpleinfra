// This file defines an IAM role called "ecs-task-execution--${var.name}",
// which is used by ECS to start the containers included in the current task.
//
// The role has the following permissions:
// - Download any image from any ECR repository.
// - Upload logs to any CloudWatch destination.
// - Access the SSM parameters in the /prod/ecs/${var.name} namespace.

data "aws_iam_policy" "aws_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

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

resource "aws_iam_role_policy_attachment" "task_execution_aws" {
  role       = aws_iam_role.task_execution.name
  policy_arn = data.aws_iam_policy.aws_task_execution.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_custom" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution.arn
}
