data "google_compute_image" "ubuntu" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2404-lts-amd64"
}

# Reserve static public IPs so hostnames remain stable for SSH/monitoring.
resource "google_compute_address" "public" {
  for_each = var.instances

  name         = each.key
  address_type = "EXTERNAL"
  ip_version   = "IPV4"

  depends_on = [google_project_service.compute]
}

# Reserve static public IPv6 addresses for each instance.
resource "google_compute_address" "public_ipv6" {
  for_each = var.instances

  name               = "${each.key}-ipv6"
  address_type       = "EXTERNAL"
  ip_version         = "IPV6"
  ipv6_endpoint_type = "VM"
  subnetwork         = google_compute_subnetwork.dev_desktops.id

  depends_on = [google_project_service.compute]
}

# One VM per dev-desktop host, tagged for firewall targeting.
resource "google_compute_instance" "instance" {
  for_each = var.instances

  name         = each.key
  machine_type = each.value.instance_type

  tags = ["dev-desktops"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = each.value.storage
      # The default choice in the Google Cloud Console.
      # It uses SSDs but limits the performance to provide a
      # more economical price point than `pd-ssd`.
      type = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dev_desktops.id
    stack_type = "IPV4_IPV6"
    access_config {
      nat_ip = google_compute_address.public[each.key].address
    }
    ipv6_access_config {
      external_ipv6 = google_compute_address.public_ipv6[each.key].address
      name          = "External IPv6"
      # Premium is the only available tier for IPv6.
      network_tier = "PREMIUM"
    }
  }

  # Same SSH key as other providers to keep access consistent for users.
  # You can find the private key in one-password searching "buildbot-west-slave-key.pem".
  metadata = {
    "ssh-keys" = "ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdGoRV9XPamZwqCMr4uk1oHWPnknzwOOSjuRBnu++WRkn7TtCM4ndDfqtKnvzlX5mzPhdvO1KKx1K8TiJ3wiq7WS4AFLGKQmPHWjg8qxGW7x4S8DHrb4ctmaujZ1+XCNSK3nsCl1lLW8DOrRlKbfeHIAllbMBZxIRmQ+XICVvhKAmSmxzTmYC8tBqvqQprG/uIuKonjLxL/ljtBxXBNECXl/JFCYG0AsB0aiuiMVeHLVzMiEppQ7YP/5Ml1Rpmn6h0dDzFtoD7xenroS98BIQF5kQWhakHbtWcNMz7DVFghWgi9wYr0gtoIshhqWYorC4yJq6HGXd0qdNHuLWNz39h"
  }
}
