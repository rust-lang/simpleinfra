output "queue_arn" {
  description = "ARN of the FIFO SQS queue that carries crates.io events for docs.rs."
  value       = aws_sqs_queue.docs_rs_events.arn
}

output "queue_name" {
  description = "Name of the FIFO SQS queue that carries crates.io events for docs.rs."
  value       = aws_sqs_queue.docs_rs_events.name
}

output "queue_url" {
  description = "URL of the FIFO SQS queue that carries crates.io events for docs.rs."
  value       = aws_sqs_queue.docs_rs_events.id
}

output "ssm_parameters" {
  description = "SSM parameter names exposing the queue ARN, name, and URL."
  value       = { for key, parameter in aws_ssm_parameter.queue : key => parameter.name }
}
