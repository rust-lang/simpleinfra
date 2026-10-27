locals {
  app_container = merge({
    name      = var.container_name
    image     = module.ecr.url
    essential = true

    logConfiguration = local.cloudwatch_logging

    environment = [
      for name, value in merge(var.environment_variables, local.datadog_app_environment) :
      {
        name  = name
        value = value
      }
    ]

    secrets = concat(
      [
        for name, param in var.secrets :
        {
          name      = name
          valueFrom = data.aws_ssm_parameter.task[param].arn
        }
      ],
      [
        for name, param in var.computed_secrets :
        {
          name      = name
          valueFrom = param
        }
      ],
    )

    portMappings = var.port_mappings
    dockerLabels = var.docker_labels
  }, var.command == null ? {} : { command = var.command }, local.datadog_app_settings)
}

# Preserve existing resource addresses for tasks without Datadog.
moved {
  from = aws_ecs_task_definition.task
  to   = aws_ecs_task_definition.task[0]
}

resource "aws_ecs_task_definition" "task" {
  count = var.datadog == null ? 1 : 0

  family                   = var.name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.task_execution.arn
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode([local.app_container])

  ephemeral_storage {
    size_in_gib = var.ephemeral_storage_gb
  }
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7
}

// ECR repository which will store the Docker image powering the application.
module "ecr" {
  source = "../ecr-repo"
  name   = var.name
}
