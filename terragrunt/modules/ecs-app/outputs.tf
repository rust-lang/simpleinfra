output "role_id" {
  value = module.ecs_task.task_execution_role_id
}

output "ci_role_name" {
  value = module.gh_oidc_ci.role.name
}
