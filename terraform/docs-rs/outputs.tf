output "storage_bucket_name" {
  description = "Legacy docs-rs storage bucket name."
  value       = aws_s3_bucket.storage.id
}
