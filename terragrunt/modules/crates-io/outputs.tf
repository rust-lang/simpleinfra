output "docs_rs_event_queue_arn" {
  description = "ARN of the SQS queue used to notify docs.rs about registry changes."
  value       = var.docs_rs_event_queue_arn
}

output "docs_rs_event_queue_name" {
  description = "Name of the SQS queue used to notify docs.rs about registry changes."
  value       = var.docs_rs_event_queue_name
}

output "docs_rs_event_queue_url" {
  description = "URL of the SQS queue used to notify docs.rs about registry changes."
  value       = var.docs_rs_event_queue_url
}
