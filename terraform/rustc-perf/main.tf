// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "rust-rustc-perf"
}

data "aws_ssm_parameter" "rustc_perf" {
  for_each = toset([
    "github-token",
    "webhook-secret",
    "collector-secret",
  ])
  name = "/prod/ecs/rustc-perf/${each.value}"
}

data "aws_ssm_parameter" "database_url" {
  name = "/prod/rds/shared/connection-urls/rustc-perf"
}

resource "aws_iam_policy" "read_database_url" {
  name = "ecs--rustc-perf"
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
  source = "../shared/modules/ecs-task"

  name   = "rustc-perf"
  cpu    = 512
  memory = 1024

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
        "awslogs-group": "/ecs/rustc-perf",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "rustc-perf"
      }
    },
    "environment": [
      {
        "name": "RUST_LOG",
        "value": "site=trace,database=trace"
      },
      {
        "name": "PORT",
        "value": "80"
      }
    ],
    "secrets": [
      {
        "name": "GITHUB_API_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.rustc_perf["github-token"].arn}"
      },
      {
        "name": "GITHUB_WEBHOOK_SECRET",
        "valueFrom": "${data.aws_ssm_parameter.rustc_perf["webhook-secret"].arn}"
      },
      {
        "name": "COLLECTOR_SECRET",
        "valueFrom": "${data.aws_ssm_parameter.rustc_perf["collector-secret"].arn}"
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
  source           = "../shared/modules/ecs-service"
  cluster_config   = data.terraform_remote_state.shared.outputs.ecs_cluster_config
  platform_version = "1.4.0"

  name        = "rustc-perf"
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container = "app"
  http_port      = 80

  domains = ["perf.rust-lang.org"]
}
