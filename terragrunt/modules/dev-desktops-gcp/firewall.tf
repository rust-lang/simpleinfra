# Ingress rules mirror AWS/Azure dev-desktop access (SSH, mosh, ping).
resource "google_compute_firewall" "dev_desktops_access" {
  name    = "${var.network_name}-access"
  network = google_compute_network.dev_desktops.name

  target_tags = ["dev-desktops"]

  # Ping access
  allow {
    protocol = "icmp"
  }

  # SSH access
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Mosh access
  allow {
    protocol = "udp"
    ports    = ["60000-61000"]
  }

  # Access from anywhere
  source_ranges = ["0.0.0.0/0"]
}

# Allow Prometheus node_exporter scraping from monitoring.infra.rust-lang.org.
resource "google_compute_firewall" "dev_desktops_node_exporter" {
  name    = "${var.network_name}-node-exporter"
  network = google_compute_network.dev_desktops.name

  target_tags = ["dev-desktops"]

  allow {
    protocol = "tcp"
    ports    = ["9100"]
  }

  source_ranges = formatlist("%s/32", data.dns_a_record_set.monitoring.addrs)
}

# Explicit egress rule documents intent for full outbound connectivity.
resource "google_compute_firewall" "dev_desktops_egress" {
  name      = "${var.network_name}-egress"
  network   = google_compute_network.dev_desktops.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Resolve the current monitoring IPs so firewall stays in sync automatically.
data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}
