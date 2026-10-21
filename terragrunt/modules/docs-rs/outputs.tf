output "s3_migration_task_arn" {
  description = "DataSync task ARN used to migrate objects from the legacy source bucket."
  value       = var.s3_migration_enabled ? aws_datasync_task.migration[0].arn : null
}

output "storage_bucket_name" {
  description = "Destination docs-rs storage bucket name."
  value       = aws_s3_bucket.storage.id
}

output "admin_task_arn" {
  description = "Task definition for one-off admin CLI commands."
  value       = module.admin.task_arn
}

output "release_task_arn" {
  description = "Task definition for the release script, derived from the admin task."
  value       = aws_ecs_task_definition.release.arn
}

output "watcher_service_arn" {
  description = "Singleton registry watcher service."
  value       = aws_ecs_service.watcher.id
}

output "builder_repository_url" {
  value = module.builder_ecr.url
}

output "builder_autoscaling_group_name" {
  description = "Auto Scaling group used to scale and refresh the builder fleet."
  value       = aws_autoscaling_group.builder.name
}

output "builder_launch_template_id" {
  value = aws_launch_template.builder.id
}

output "builder_launch_template_version" {
  value = aws_launch_template.builder.latest_version
}
