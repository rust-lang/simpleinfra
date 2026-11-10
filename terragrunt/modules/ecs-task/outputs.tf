locals {
  # Exactly one task definition exists, depending on var.datadog. The Datadog
  # module re-exports its aws_ecs_task_definition attributes under the same
  # names, so either can be read like an `aws_ecs_task_definition`.
  task_definition = one(concat(aws_ecs_task_definition.task, module.datadog_ecs_fargate_task))
}

output "task_arn" {
  value = local.task_definition.arn
}

output "task_definition" {
  description = "Task definition settings for derived tasks sharing the same image, roles, and configuration."
  value = {
    arn                      = local.task_definition.arn
    cpu                      = local.task_definition.cpu
    memory                   = local.task_definition.memory
    network_mode             = local.task_definition.network_mode
    task_role_arn            = local.task_definition.task_role_arn
    execution_role_arn       = local.task_definition.execution_role_arn
    requires_compatibilities = local.task_definition.requires_compatibilities
    container_definitions    = local.task_definition.container_definitions
    ephemeral_storage        = local.task_definition.ephemeral_storage
    tags                     = local.task_definition.tags
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
