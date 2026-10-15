output "role_id" {
  value = module.ecs_task.task_execution_role_id
}

output "oidc_role_id" {
  value = local.oidc_role_id
}
