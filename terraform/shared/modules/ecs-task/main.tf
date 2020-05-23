// This information is needed to produce policies in iam.tf.
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

// A CloudWatch log group called "/ecs/task-name" is automatically created
// along with each task, and the task has the required permissions to push logs
// to it, as well as creating log streams inside it.
//
// It should be the preferred way to store the logs produced by the container.
resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_task_definition" "task" {
  family       = var.name
  cpu          = var.cpu
  memory       = var.memory
  network_mode = "awsvpc"

  execution_role_arn       = aws_iam_role.task_execution.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = var.containers
  dynamic "volume" {
    for_each = var.volume == null ? toset([]) : toset([1])
    content {
      efs_volume_configuration {
        file_system_id = var.volume.dns_name
        root_directory = "/"
      }
      name = "service-storage"
    }
  }
}
