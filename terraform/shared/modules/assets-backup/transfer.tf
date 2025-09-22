resource "google_storage_transfer_job" "backup_transfer" {
  for_each = var.source_buckets

  project = var.project_id

  name        = "transferJobs/transfer-${each.key}"
  description = "Transfer for ${each.value.description}"

  transfer_spec {
    http_data_source {
      list_url = "https://${each.value.cloudfront_domain}/"
    }

    gcs_data_sink {
      bucket_name = google_storage_bucket.backup_buckets[each.key].name
    }

    transfer_options {
      delete_objects_from_source_after_transfer  = false
      overwrite_objects_already_existing_in_sink = true
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
