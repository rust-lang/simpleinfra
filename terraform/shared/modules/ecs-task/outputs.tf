output "arn" {
  description = "The ARN of the task definition created by this module."
  value       = aws_ecs_task_definition.task.arn
}

output "execution_role_name" {
  description = "The name of the task execution role created by this module."
  value       = aws_iam_role.task_execution.name
}
