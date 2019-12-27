data "aws_ecr_repository" "highfive" {
  name = "rust-highfive"
}

data "aws_ssm_parameter" "highfive" {
  for_each = toset(["github-token", "webhook-secrets"])
  name     = "/prod/ecs/highfive/${each.value}"
}

module "task_highfive" {
  source = "./task"

  name   = "highfive"
  cpu    = 256
  memory = 512

  log_retention_days = 7
  ecr_repositories_arns = [
    data.aws_ecr_repository.highfive.arn,
  ]

  containers = <<EOF
[
  {
    "name": "app",
    "image": "${data.aws_ecr_repository.highfive.repository_url}",
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
        "awslogs-group": "/ecs/highfive",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "highfive"
      }
    },
    "secrets": [
      {
        "name": "HIGHFIVE_GITHUB_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.highfive["github-token"].arn}"
      },
      {
        "name": "HIGHFIVE_WEBHOOK_SECRETS",
        "valueFrom": "${data.aws_ssm_parameter.highfive["webhook-secrets"].arn}"
      }
    ]
  }
]
EOF
}

module "service_highfive" {
  source         = "./service"
  cluster_config = local.cluster_config

  name        = "highfive"
  task_arn    = module.task_highfive.arn
  tasks_count = 1

  http_container = "app"
  http_port      = 80

  domains = {
    "highfive.${var.load_balancer_domain}" = var.dns_zone,
  }
}
