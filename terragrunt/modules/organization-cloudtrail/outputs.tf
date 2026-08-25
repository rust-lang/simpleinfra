output "bucket_name" {
  description = "S3 bucket receiving organization CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "datadog_forwarder_arn" {
  description = "Lambda function forwarding CloudTrail logs to Datadog"
  value       = module.datadog_forwarder.datadog_forwarder_arn
}

output "datadog_log_sources" {
  description = "AWS log sources to auto-subscribe to the Datadog Forwarder"
  value       = ["cloudtrail"]
}

output "trail_arn" {
  description = "Organization CloudTrail ARN"
  value       = aws_cloudtrail.organization.arn
}
