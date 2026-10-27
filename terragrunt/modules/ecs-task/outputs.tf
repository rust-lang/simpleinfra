output "task_arn" {
  value = var.datadog == null ? aws_ecs_task_definition.task[0].arn : module.datadog_ecs_fargate_task[0].arn
}

output "task_definition" {
  description = "Task definition settings for derived tasks sharing the same image, roles, and configuration."
  value = {
    arn                      = var.datadog == null ? aws_ecs_task_definition.task[0].arn : module.datadog_ecs_fargate_task[0].arn
    cpu                      = tostring(var.cpu)
    memory                   = tostring(var.memory)
    network_mode             = "awsvpc"
    task_role_arn            = aws_iam_role.task.arn
    execution_role_arn       = aws_iam_role.task_execution.arn
    requires_compatibilities = ["FARGATE"]
    container_definitions    = var.datadog == null ? aws_ecs_task_definition.task[0].container_definitions : module.datadog_ecs_fargate_task[0].container_definitions
    ephemeral_storage        = [{ size_in_gib = var.ephemeral_storage_gb }]
    tags                     = var.datadog == null ? aws_ecs_task_definition.task[0].tags : module.datadog_ecs_fargate_task[0].tags
  }
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
