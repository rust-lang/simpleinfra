output "arn" {
  description = "The ARN of the task definition created by this module."
  value = aws_ecs_task_definition.task.arn
}
