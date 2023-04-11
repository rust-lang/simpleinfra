locals {
  name = "fastly-exporter"
}

data "aws_ssm_parameter" "fastly_api_token" {
  name = "/prod/fastly-exporter/fastly/api-token"
}

resource "aws_iam_policy" "read_fastly_api_token" {
  name = "ecs--${local.name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadingFastlyApiToken"
        Effect   = "Allow"
        Action   = "ssm:GetParameters"
        Resource = data.aws_ssm_parameter.fastly_api_token.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_fastly_api_token" {
  role       = module.ecs_task.execution_role_name
  policy_arn = aws_iam_policy.read_fastly_api_token.arn
}

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name   = local.name
  cpu    = 256
  memory = 512

  log_retention_days = 7
  ecr_repositories_arns = [
    # This repository does not exist, since we're pulling the imge directly from GitHub.
    # But the task module cannot be applied without providing at least one ARN here.
    "arn:aws:ecr:us-west-1:890664054962:repository/fastly-exporter"
  ]

  containers = <<EOF
[
  {
    "name": "${local.name}",
    "image": "ghcr.io/fastly/fastly-exporter:v7.4.0",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${local.name}",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "${local.name}"
      }
    },
    "environment": [],
    "secrets": [
      {
        "name": "FASTLY_API_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.fastly_api_token.arn}"
      }
    ]
  }
]
EOF
}

resource "aws_security_group" "fastly_exporter" {
  name        = "fastly-exporter"
  description = "Allow Prometheus to scrape the fastly-exporter"
  vpc_id      = data.terraform_remote_state.shared.outputs.ecs_cluster_config.vpc_id

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    # Elastic IP of the monitoring server
    cidr_blocks = ["52.9.166.219/32"]
    # Load balancer security group, required for health checks
    security_groups = ["sg-0ddcb954525a46b70"]
  }
}

module "ecs_service" {
  source = "../shared/modules/ecs-service"

  cluster_config   = data.terraform_remote_state.shared.outputs.ecs_cluster_config
  platform_version = "1.4.0"

  name        = local.name
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container = local.name
  http_port      = 8080

  domains = ["fastly-exporter.infra.rust-lang.org"]

  additional_security_group_ids = [
    aws_security_group.fastly_exporter.id,
  ]
}
