// Deploy the bot on the production ECS cluster.

// Load parameters that will be included in the task definition.

data "aws_ssm_parameter" "mods_bot" {
  for_each = toset([
    "discord-token",
  ])
  name = "/prod/ecs/discord-mods-bot/${each.value}"
}

data "aws_ssm_parameter" "database_url" {
  name = "/prod/rds/shared/connection-urls/discord-mods-bot"
}

// Authorize the bot to read the its database URL.

resource "aws_iam_policy" "read_database_url" {
  name = "ecs--discord-mods-bot"
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

// Define the ECS task that will be run on the server

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name   = "discord-mods-bot"
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
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/discord-mods-bot",
        "awslogs-region": "us-west-1",
        "awslogs-stream-prefix": "discord-mods-bot"
      }
    },
    "environment": [
      {
        "name": "MOD_ID",
        "value": "447147786652221441"
      },
      {
        "name": "TALK_ID",
        "value": "531929276086484992"
      },
      {
        "name": "WG_AND_TEAMS",
        "value": "590248810127818752"
      }
    ],
    "secrets": [
      {
        "name": "DISCORD_TOKEN",
        "valueFrom": "${data.aws_ssm_parameter.mods_bot["discord-token"].arn}"
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

// Run the task in the ECS cluster.
//
// This does not use the ecs-service shared module, as the bot doesn't expose
// any HTTP port and doesn't need a load balancer.

resource "aws_ecs_service" "service" {
  name            = "discord-mods-bot"
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
