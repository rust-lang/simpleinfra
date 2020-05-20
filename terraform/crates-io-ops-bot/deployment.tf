// Deploys the bot to the production ECS cluster

// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../../modules/ecr-repo"
  name   = "crates-io-ops-bot"
}

// This just loads the data for each of these secrets
// The values are added to ASM manually
data "aws_ssm_parameter" "crates_io_ops_bot" {
  for_each = to_set([
      "discord_token",
      "heroku_api_key",
      "build_check_interval",
      "github_org",
      "github_repo",
      "github_token"
  ])
  name     = "prod/ecs/crates_io_ops_bot/${each.value}"
}

module "ecs_task" {
    source = "../../modules/ecs-task"

    name   = "crates_io_ops"
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
        "awslogs-group": "/ecscratesioops",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "cratesioops"
      }
    },
    "secrets": [
      {
        "name": "DISCORD_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.highfive["discord_token"].arn}"
      },
      {
        "name": "HEROKU_API_KEY",
        "valueFrom": "${data.aws_ssm_parameter.highfive["heroku_api_key"].arn}"
      },
      {
        "name": "BUILD_CHECK_INTERVAL",
        "valueFrom": "${data.aws_ssm_parameter.highfive["build_check_interval"].arn}"
      },
      {
        "name": "GITHUB_ORG",
        "valueFrom": "${data.aws_ssm_parameter.highfive["github_org"].arn}"
      },
      {
        "name": "GITHUB_REPO",
        "valueFrom": "${data.aws_ssm_parameter.highfive["github_repo"].arn}"
      },
      {
        "name": "GITHUB_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.highfive["github_token"].arn}"
      }
    ]
  }
]
EOF
}

module "ecs_service" {
    source         = "../../modules/ecs-service"
    cluster_config = var.cluster_config

    name           = "cratesioops"
    task_arn       = module.ecs_task.arn
    tasks_count    = 1

    http_counter   = "app"
    http_port      = 80


    domains = [
        var.domain_name
    ]
}