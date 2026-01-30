# Ensure the Compute Engine API is enabled before provisioning resources.
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

# Dedicated VPC to isolate dev desktops from other GCP workloads.
resource "google_compute_network" "dev_desktops" {
  name = local.network_name
  # For ipv6 support we need custom subnets
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

# Dual-stack subnet to support both external IPv4 and IPv6 addresses.
resource "google_compute_subnetwork" "dev_desktops" {
  name          = local.network_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"

  network    = google_compute_network.dev_desktops.id
  depends_on = [google_project_service.compute]
}
