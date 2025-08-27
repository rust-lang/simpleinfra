# Create GCS buckets for backup storage
resource "google_storage_bucket" "backup_buckets" {
  for_each = var.source_buckets

  name     = "backup-${each.key}"
  location = var.region
  project  = var.project_id

  # Use Archive storage class for cost optimization
  storage_class = "ARCHIVE"

  # Enable versioning to protect against accidental deletion/modification
  versioning {
    enabled = true
  }

  # Configure soft delete policy to retain deleted objects for recovery
  # for a certain period of time
  soft_delete_policy {
    retention_duration_seconds = 7776000 # 90 days
  }

  labels = {
    purpose    = "rust-assets-backup"
    source     = each.key
    managed-by = "terraform"
  }
}
