resource "google_storage_transfer_job" "backup_transfer" {
  for_each = var.source_buckets

  project = var.project_id

  name        = "transferJobs/transfer-${each.key}"
  description = "Transfer for ${each.value.description}"

  transfer_spec {
    aws_s3_data_source {
      bucket_name       = each.value.bucket_name
      cloudfront_domain = "https://${each.value.cloudfront_id}.cloudfront.net"
      aws_access_key {
        access_key_id     = each.value.aws_access_key_id
        secret_access_key = data.google_secret_manager_secret_version.aws_secret_access_key[each.key].secret_data
      }
    }

    gcs_data_sink {
      bucket_name = google_storage_bucket.backup_buckets[each.key].name
    }

    transfer_options {
      delete_objects_from_source_after_transfer = false

      # Mirror AWS S3 deletions into the crates.io backup bucket only.
      #
      # Mirroring a delete doesn't destroy data: the backup bucket is
      # versioned, so the object only becomes a noncurrent version.
      # That version is hidden from normal listings, but it can still
      # be read and restored by its generation number. It's kept until someone
      # deletes it, because the bucket has no lifecycle rule.
      #
      # Please do not ever add a lifecycle rule to this, we want the retention
      # and this is a GDPR exempt security retention.
      #
      # See:
      # https://github.com/rust-lang/infra-team/blob/main/service-catalog/rust-assets-backup/maintenance.md#backup-maintenance-
      delete_objects_unique_in_sink = each.key == "crates-io"
    }
  }

  schedule {
    schedule_start_date {
      year  = 2025
      month = 9
      day   = 19
    }
    # If unspecified, the job runs one time only, at the start date
    schedule_end_date {
      year  = 2099
      month = 12
      day   = 31
    }
    # Pick a specific start time to avoid conflicting with other automated tasks
    start_time_of_day {
      hours   = 6
      minutes = 24
      seconds = 0
      nanos   = 0
    }
  }
}
