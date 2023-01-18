// Task definition of the application, which specifies which containers should
// be part of the task and which settings do they have.
resource "aws_ecs_task_definition" "task" {
  family       = var.name
  cpu          = var.cpu
  memory       = var.memory
  network_mode = "awsvpc"

  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.task_execution.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = module.ecr.url
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "app"
        }
      }

      environment = [
        for name, value in var.environment_variables :
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
    }
  ])

  ephemeral_storage {
    size_in_gib = var.ephemeral_storage_gb
  }
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/${var.env}/${var.name}"
  retention_in_days = 7
}

// ECR repository which will store the Docker image powering the application.
module "ecr" {
  source = "../ecr-repo"
  name   = var.name
}
