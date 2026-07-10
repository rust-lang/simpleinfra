output "queue_arn" {
  description = "ARN of the queue carrying crates.io index changes for docs.rs."
  value       = aws_sqs_queue.index_changes.arn
}

output "queue_name" {
  description = "Name of the queue carrying crates.io index changes for docs.rs."
  value       = aws_sqs_queue.index_changes.name
}

output "queue_url" {
  description = "URL applications use to send or receive docs.rs index changes."
  value       = aws_sqs_queue.index_changes.url
}
