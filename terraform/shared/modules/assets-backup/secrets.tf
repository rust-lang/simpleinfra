# Fetch AWS secret access key from Google Secret Manager for each S3 bucket
data "google_secret_manager_secret_version" "aws_secret_access_key" {
  for_each = var.source_buckets

  project = var.project_id
  secret  = "${each.value.bucket_name}--access-key--${each.value.aws_access_key_id}"
}
