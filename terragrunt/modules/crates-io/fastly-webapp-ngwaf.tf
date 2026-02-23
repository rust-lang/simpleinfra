# Next-Gen WAF workspace
resource "fastly_ngwaf_workspace" "webapp" {
  name        = "${var.webapp_domain_name}-waf"
  description = "Next-Gen WAF workspace for ${var.webapp_domain_name}"
  # TODO: at some point `block` instead of just logging
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

# The upload endpoint can legitimately contain payloads that trigger these anomalies.
# Restrict the suppression to PUT /api/v1/crates/new only.
# Signal names retrieved by creating a rule manually and querying the Fastly API for that rule's configuration.
resource "fastly_ngwaf_workspace_rule" "webapp_allow_null_byte_on_crate_upload" {
  workspace_id = fastly_ngwaf_workspace.webapp.id
  type         = "signal"
  description  = "Allow null-byte anomaly for crate uploads"
  enabled      = true

  group_operator = "all"
  condition {
    field    = "method"
    operator = "equals"
    value    = "PUT"
  }
  condition {
    field    = "path"
    operator = "equals"
    value    = "/api/v1/crates/new"
  }

  action {
    type   = "exclude_signal"
    signal = "NULLBYTE"
  }
}

resource "fastly_ngwaf_workspace_rule" "webapp_allow_invalid_encoding_on_crate_upload" {
  workspace_id = fastly_ngwaf_workspace.webapp.id
  type         = "signal"
  description  = "Allow Invalid Encoding anomaly for crate uploads"
  enabled      = true

  group_operator = "all"
  condition {
    field    = "method"
    operator = "equals"
    value    = "PUT"
  }
  condition {
    field    = "path"
    operator = "equals"
    value    = "/api/v1/crates/new"
  }

  action {
    type   = "exclude_signal"
    signal = "NOTUTF8"
  }
}

# Custom signal used for per-client rate limiting in the webapp workspace.
resource "fastly_ngwaf_workspace_signal" "webapp_rate_limit" {
  workspace_id = fastly_ngwaf_workspace.webapp.id
  name         = "webapp-rate-limit"
  description  = "webapp per-IP rate limiting"
}

resource "fastly_ngwaf_workspace_rule" "webapp_per_ip_rate_limit" {
  workspace_id = fastly_ngwaf_workspace.webapp.id
  type         = "rate_limit"
  description  = "Rate limit per client IP to 3,600 requests per hour"
  enabled      = true

  # Fastly NGWAF requires at least one rule condition.
  # Match all request paths so the rate limit applies globally.
  group_operator = "all"
  condition {
    field    = "path"
    operator = "contains"
    value    = "/"
  }

  # If the workspace mode isn't "block", then this rule is not enforced.
  action {
    signal = "site.webapp-rate-limit"
    type   = "block_signal"
  }

  # If an IP sends 600 req in 10 minutes, block them for 5 minutes.
  rate_limit {
    signal = fastly_ngwaf_workspace_signal.webapp_rate_limit.reference_id
    # Maximum number of requests within the evaluation window before the rate limit is triggered.
    threshold = 600
    # Rate limit evaluation window in seconds.
    # Fastly NGWAF only supports rate-limit windows of 1 or 10 minutes.
    # 10 minutes.
    interval = 600
    # How long the rate limit is enforced (in seconds). 5 minutes.
    duration = 300

    client_identifiers {
      type = "ip"
    }
  }
}
