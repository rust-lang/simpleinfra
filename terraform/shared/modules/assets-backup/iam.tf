data "google_storage_transfer_project_service_account" "transfer_service_account" {
  project = var.project_id
}

resource "google_storage_bucket_iam_member" "backup_buckets_transfer_agent_object_admin" {
  for_each = google_storage_bucket.backup_buckets

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.transfer_service_account.email}"
}

resource "google_storage_bucket_iam_member" "backup_buckets_transfer_agent_bucket_reader" {
  for_each = google_storage_bucket.backup_buckets

  bucket = each.value.name
  # the non legacy role is still in beta and it's not available.
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.transfer_service_account.email}"
}
