# The service account configured with read-only scopes on GWS Admin settings
resource "google_service_account" "gws-readonly-sa" {
  account_id   = "gws-readonly-sa"
  display_name = "gws-readonly-sa"
  project      = "rustlang-gws-iac"
}

# The service account key used for read-only access in API integrations
resource "google_service_account_key" "gws-readonly-sa-key" {
  service_account_id = google_service_account.gws-readonly-sa.name
}
