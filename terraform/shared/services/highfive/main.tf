// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../../modules/ecr-repo"
  name   = "rust-highfive"
}

// The application is hosted on an ECS cluster. The following modules setup
// both the task definition, and the actual service running on the cluster.

data "aws_ssm_parameter" "highfive" {
  for_each = toset(["github-token", "webhook-secrets"])
  name     = "/prod/ecs/highfive/${each.value}"
}

module "ecs_task" {
  source = "../../modules/ecs-task"

  name   = "highfive"
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

module "ecs_service" {
  source         = "../../modules/ecs-service"
  cluster_config = var.cluster_config

  name        = "highfive"
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container = "app"
  http_port      = 80

  domains = [
    var.domain_name,
  ]
}
