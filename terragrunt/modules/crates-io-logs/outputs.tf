# ARN of the SQS queue that receives S3 bucket notifications
output "sqs_queue_arn" {
  value = aws_sqs_queue.cdn_log_event_queue.arn
}
