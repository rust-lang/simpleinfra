// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../../modules/ecr-repo"
  name   = "rust-triagebot"
}

data "aws_ssm_parameter" "triagebot" {
  for_each = toset([
    "github-token",
    "webhook-secret",
    "zulip-token",
    "zulip-api-token",
    "github-app-private-key",
  ])
  name = "/prod/ecs/triagebot/${each.value}"
}

data "aws_ssm_parameter" "database_url" {
  name = "/prod/rds/shared/connection-urls/triagebot"
}

resource "aws_iam_policy" "read_database_url" {
  name = "ecs--triagebot"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadingConnectionUrl"
        Effect   = "Allow"
        Action   = "ssm:GetParameters"
        Resource = data.aws_ssm_parameter.database_url.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_database_url" {
  role       = module.ecs_task.execution_role_name
  policy_arn = aws_iam_policy.read_database_url.arn
}

module "ecs_task" {
  source = "../../modules/ecs-task"

  name   = "triagebot"
  cpu    = 256
  memory = 512

  log_retention_days = 7
  ecr_repositories_arns = [
    module.ecr.arn,
  ]

  containers = <<EOF
[
  {
    "name": "app",
    "image": "${module.ecr.url}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/triagebot",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "triagebot"
      }
    },
    "environment": [
      {
        "name": "RUST_LOG",
        "value": "parser=trace,triagebot=trace"
      }
    ],
    "secrets": [
      {
        "name": "GITHUB_API_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.triagebot["github-token"].arn}"
      },
      {
        "name": "GITHUB_WEBHOOK_SECRET",
        "valueFrom": "${data.aws_ssm_parameter.triagebot["webhook-secret"].arn}"
      },
      {
        "name": "ZULIP_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.triagebot["zulip-token"].arn}"
      },
      {
        "name": "ZULIP_API_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.triagebot["zulip-api-token"].arn}"
      },
      {
        "name": "GITHUB_APP_PRIVATE_KEY",
        "valueFrom": "${data.aws_ssm_parameter.triagebot["github-app-private-key"].arn}"
      },
      {
        "name": "DATABASE_URL",
        "valueFrom": "${data.aws_ssm_parameter.database_url.arn}"
      }
    ]
  }
]
EOF
}

module "ecs_service" {
  source         = "../../modules/ecs-service"
  cluster_config = var.cluster_config

  name        = "triagebot"
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container = "app"
  http_port      = 80

  domains = [
    var.domain_name,
    "triage.rust-lang.org",
  ]
}
