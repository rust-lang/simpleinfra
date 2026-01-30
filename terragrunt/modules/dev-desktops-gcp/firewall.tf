# Ingress rules mirror AWS/Azure dev-desktop access (SSH, mosh, ping).
resource "google_compute_firewall" "dev_desktops_access_ipv4" {
  name    = "${local.network_name}-access-ipv4"
  network = google_compute_network.dev_desktops.id

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

  # Access from anywhere (IPv4)
  source_ranges = ["0.0.0.0/0"]
}

# IPv6 ingress rules mirror IPv4 access (SSH, mosh, ping).
resource "google_compute_firewall" "dev_desktops_access_ipv6" {
  name    = "${local.network_name}-access-ipv6"
  network = google_compute_network.dev_desktops.id

  target_tags = ["dev-desktops"]

  # Ping access (IPv6)
  allow {
    # protocol number for ICMPv6
    protocol = "58"
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

  # Access from anywhere (IPv6)
  source_ranges = ["::/0"]
}

# Allow Prometheus node_exporter scraping from monitoring.infra.rust-lang.org.
resource "google_compute_firewall" "dev_desktops_node_exporter" {
  name    = "${local.network_name}-node-exporter"
  network = google_compute_network.dev_desktops.id

  target_tags = ["dev-desktops"]

  allow {
    protocol = "tcp"
    ports    = ["9100"]
  }

  source_ranges = formatlist("%s/32", data.dns_a_record_set.monitoring.addrs)
}

# Explicit egress rule documents intent for full outbound connectivity.
resource "google_compute_firewall" "dev_desktops_egress_ipv4" {
  name      = "${local.network_name}-egress-ipv4"
  network   = google_compute_network.dev_desktops.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# IPv6 egress rule documents intent for full outbound connectivity.
resource "google_compute_firewall" "dev_desktops_egress_ipv6" {
  name      = "${local.network_name}-egress-ipv6"
  network   = google_compute_network.dev_desktops.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["::/0"]
}

# Resolve the current monitoring IPs so firewall stays in sync automatically.
data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}
