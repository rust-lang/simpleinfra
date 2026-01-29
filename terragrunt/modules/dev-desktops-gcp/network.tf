# Ensure the Compute Engine API is enabled before provisioning resources.
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

# Dedicated VPC to isolate dev desktops from other GCP workloads.
resource "google_compute_network" "dev_desktops" {
  name                    = var.network_name
  auto_create_subnetworks = true

  depends_on = [google_project_service.compute]
}
