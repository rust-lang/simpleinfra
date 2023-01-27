output "task_arn" {
  value = aws_ecs_task_definition.task.arn
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
