output "task_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "task_definition" {
  description = "Task definition settings for derived tasks sharing the same image, roles, and configuration."
  value       = aws_ecs_task_definition.task
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}

output "task_execution_role_id" {
  value = aws_iam_role.task.id
}

output "policy_push_arn" {
  value = module.ecr.policy_push_arn
}

output "policy_pull_arn" {
  value = module.ecr.policy_pull_arn
}
