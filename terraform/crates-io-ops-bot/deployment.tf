// Deploys the bot to the production ECS cluster

// This just loads the data for each of these secrets
// The values are added to SSM parameter store manually
data "aws_ssm_parameter" "crates_io_ops_bot" {
  for_each = toset([
    "discord-token",
    "heroku-api-key",
    "github-token"
  ])
  name = "/prod/ecs/crates-io-ops-bot/${each.value}"
}

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name               = "crates-io-ops-bot"
  cpu                = 256
  memory             = 512
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
        "awslogs-group": "/ecs/crates-io-ops-bot",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "crates-io-ops-bot"
      }
    },
    "environment": [
      {
        "name": "BUILD_CHECK_INTERVAL",
        "value": "180"
      },
      {
         "name": "BUILD_MESSAGE_DISPLAY_INTERVAL",
          "value": "600"
      },
      {
        "name": "GITHUB_ORG",
        "value": "rust-lang"
      },
      {
        "name": "GITHUB_REPO",
        "value": "crates.io"
      }
    ],
    "secrets": [
      {
        "name": "DISCORD_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["discord-token"].arn}"
      },
      {
        "name": "HEROKU_API_KEY",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["heroku-api-key"].arn}"
      },
      {
        "name": "GITHUB_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["github-token"].arn}"
      }
    ]
  }
]
EOF
}

// Run the task in the ECS cluster.
//
// This does not use the ecs-service shared module, as the bot doesn't expose
// any HTTP port and doesn't need a load balancer.

resource "aws_ecs_service" "service" {
  name             = "crates-io-ops-bot"
  cluster          = data.terraform_remote_state.shared.outputs.ecs_cluster_config.cluster_id
  task_definition  = module.ecs_task.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_ecs_managed_tags = true

  network_configuration {
    subnets          = data.terraform_remote_state.shared.outputs.ecs_cluster_config.subnet_ids
    security_groups  = [data.terraform_remote_state.shared.outputs.ecs_cluster_config.service_security_group_id]
    assign_public_ip = false
  }
}
