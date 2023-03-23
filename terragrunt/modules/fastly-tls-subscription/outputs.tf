output "destinations" {
  # It is currently not possible to get the CNAME for TLS-enabled hostnames as a
  # Terraform resource. But the ACME HTTP challenge redirects production traffic
  # to Fastly, for which it uses the CNAME that we are looking for.
  #
  # The below snippet is a hack to get the CNAME for the static domain from the
  # HTTP challenge, until Fastly exposes it in the Terraform provider.
  value = flatten([
    for record in fastly_tls_subscription.subscription.managed_http_challenges :
    record.record_values if record.record_type == "CNAME"
  ])
}
