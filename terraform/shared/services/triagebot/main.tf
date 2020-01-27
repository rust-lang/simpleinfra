// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../../modules/ecr-repo"
  name   = "rust-triagebot"
}

data "aws_ssm_parameter" "triagebot" {
  for_each = toset(["github-token", "webhook-secret"])
  name     = "/prod/ecs/triagebot/${each.value}"
}

resource "random_password" "db" {
  length           = 25
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "triagebot" {
  name     = "triagebot"
  login    = true
  password = random_password.db.result
}

resource "postgresql_database" "triagebot" {
  name              = "triagebot"
  owner             = postgresql_role.triagebot.name
  template          = "template0"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  allow_connections = true
}

data "aws_db_instance" "database" {
  db_instance_identifier = "shared"
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
      },
      {
        "name": "DATABASE_URL",
        "value": "postgres://triagebot:${random_password.db.result}@${data.aws_db_instance.database.address}/triagebot"
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
  ]
}
