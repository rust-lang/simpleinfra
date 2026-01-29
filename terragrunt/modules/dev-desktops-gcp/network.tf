# Dedicated VPC to isolate dev desktops from other GCP workloads.
resource "google_compute_network" "dev_desktops" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Regional subnet keeps the IP space explicit and avoids auto subnet creation.
resource "google_compute_subnetwork" "dev_desktops" {
  name          = "${var.network_name}-${var.region}"
  network       = google_compute_network.dev_desktops.id
  ip_cidr_range = var.subnet_cidr
}
