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
  }
}
