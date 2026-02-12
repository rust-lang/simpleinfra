output "s3_migration_task_arn" {
  description = "DataSync task ARN used to migrate objects from the legacy source bucket."
  value       = var.s3_migration_enabled ? aws_datasync_task.migration[0].arn : null
}

output "storage_bucket_name" {
  description = "Destination docs-rs storage bucket name."
  value       = aws_s3_bucket.storage.id
}
