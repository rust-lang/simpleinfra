# Create GCS buckets for backup storage
resource "google_storage_bucket" "backup_buckets" {
  for_each = var.source_buckets

  # On prod, the original bucket name is prefixed with gcp- to avoid conflicts.
  # Because in GCP, bucket names need to be globally unique.
  # Going back, I would have specified the name in the variable directly, instead
  # of editing the name programmatically here.
  name     = "${lower(var.environment) == "prod" ? "gcp-" : ""}backup-${each.key}"
  location = var.region
  project  = var.project_id

  # Use Archive storage class for cost optimization
  storage_class = "ARCHIVE"

  # Enable versioning to protect against accidental deletion/modification
  versioning {
    enabled = true
  }

  # Please do not ever add a lifecycle rule to these buckets. We want to keep
  # noncurrent versions forever: for crates.io this is a GDPR exempt security
  # retention (see transfer.tf).

  # Hardening against accidental console exposure:
  # Backups should never be publicly readable
  # Access is managed through IAM, not object ACLs
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  # Configure soft delete policy to retain deleted objects for recovery
  # for a certain period of time
  soft_delete_policy {
    retention_duration_seconds = 7776000 # 90 days
  }
}
