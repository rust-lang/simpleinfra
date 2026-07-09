output "s3_migration_task_arn" {
  description = "DataSync task ARN used to migrate objects from the legacy source bucket."
  value       = var.s3_migration_enabled ? aws_datasync_task.migration[0].arn : null
}

output "storage_bucket_name" {
  description = "Destination docs-rs storage bucket name."
  value       = aws_s3_bucket.storage.id
}

output "crates_io_event_queue_arn" {
  description = "ARN of the SQS queue used by crates.io to notify docs.rs about registry changes."
  value       = var.crates_io_event_queue_arn
}

output "crates_io_event_queue_name" {
  description = "Name of the SQS queue used by crates.io to notify docs.rs about registry changes."
  value       = var.crates_io_event_queue_name
}

output "crates_io_event_queue_url" {
  description = "URL of the SQS queue used by crates.io to notify docs.rs about registry changes."
  value       = var.crates_io_event_queue_url
}
