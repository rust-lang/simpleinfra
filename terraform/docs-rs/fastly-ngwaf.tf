# Next-Gen WAF workspace
resource "fastly_ngwaf_workspace" "webapp" {
  name        = "${local.domain_name}-waf"
  description = "Next-Gen WAF workspace for ${local.domain_name}"

  # switch to blocking mode when rules are updated
  mode = "log"

  # Configure when the WAF should flag an IP address as potentially malicious based on cumulative attack signals over different time windows.
  #
  # Fastly's Next-Gen WAF analyzes each request and assigns attack signals when it detects suspicious patterns
  # (SQL injection attempts, XSS, path traversal, etc.). These signals accumulate per IP address over time.
  attack_signal_thresholds {
    # If an IP accumulates 100+ attack signals within 1 minute, it's flagged as an attacker
    one_minute = 100
    # If an IP accumulates 500+ attack signals within 10 minutes, it's flagged
    ten_minutes = 500
    # If an IP accumulates 1000+ attack signals within 1 hour, it's flagged
    one_hour = 1000
    # If true, a single attack signal immediately blocks the IP.
    # We set it to false, to allow for legitimate edge cases
    immediate = false
  }
}

resource "sigsci_edge_deployment" "deployment" {
  site_short_name = fastly_ngwaf_workspace.name
  authorized_services = [
    fastly_service_compute.docs_rs.id
  ]
}
