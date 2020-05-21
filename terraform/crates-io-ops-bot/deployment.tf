// Deploys the bot to the production ECS cluster

// The ECR repository is used by CI to store the container image, which will
// then be fetched by the ECS service.
module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "crates-io-ops-bot"
}

// This just loads the data for each of these secrets
// The values are added to ASM manually
data "aws_ssm_parameter" "crates_io_ops_bot" {
  for_each = toset([
    "discord_token",
    "heroku_api_key",
    "build_check_interval",
    "github_org",
    "github_repo",
    "github_token"
  ])
  name = "/prod/ecs/crates_io_ops_bot/${each.value}"
}

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name               = "crates_io_ops"
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
        "awslogs-group": "/ecscratesioops",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "cratesioops"
      }
    },
    "secrets": [
      {
        "name": "DISCORD_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["discord_token"].arn}"
      },
      {
        "name": "HEROKU_API_KEY",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["heroku_api_key"].arn}"
      },
      {
        "name": "BUILD_CHECK_INTERVAL",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["build_check_interval"].arn}"
      },
      {
        "name": "GITHUB_ORG",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["github_org"].arn}"
      },
      {
        "name": "GITHUB_REPO",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["github_repo"].arn}"
      },
      {
        "name": "GITHUB_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.crates_io_ops_bot["github_token"].arn}"
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
  name            = "crates-io-ops-bot"
  cluster         = data.terraform_remote_state.shared.outputs.ecs_cluster_config.cluster_id
  task_definition = module.ecs_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_ecs_managed_tags = true

  network_configuration {
    subnets          = data.terraform_remote_state.shared.outputs.ecs_cluster_config.subnet_ids
    security_groups  = [data.terraform_remote_state.shared.outputs.ecs_cluster_config.service_security_group_id]
    assign_public_ip = false
  }
}