data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "task" {
  family       = var.name
  cpu          = var.cpu
  memory       = var.memory
  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.task_execution.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = var.containers
}
