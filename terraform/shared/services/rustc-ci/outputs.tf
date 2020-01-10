output "caches_bucket_arn" {
  value = aws_s3_bucket.caches.arn
}

output "artifacts_bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}
