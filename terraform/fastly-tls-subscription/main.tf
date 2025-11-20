resource "fastly_tls_subscription" "subscription" {
  certificate_authority = var.certificate_authority
  domains               = var.domains
}

resource "aws_route53_record" "tls_validation" {
  depends_on = [fastly_tls_subscription.subscription]

  for_each = {
    # The following `for` expression (due to the outer {}) will produce an object with key/value pairs:
    #   - The 'key' is the domain name we've configured (e.g. fastly-static.crates.io)
    #   - The 'value' is a specific 'challenge' object whose record_name matches the domain
    #     (e.g. record_name is _acme-challenge.fastly-static.crates.io).
    for domain in fastly_tls_subscription.subscription.domains :
    # `element()` returns the first object in the list which should be the relevant 'challenge' object we need
    domain => element([
      for obj in fastly_tls_subscription.subscription.managed_dns_challenges :
      # We use an `if` conditional to filter the list to a single element
      obj if obj.record_name == "_acme-challenge.${domain}"
    ], 0)
  }

  name            = each.value.record_name
  type            = each.value.record_type
  zone_id         = var.aws_route53_zone_id
  allow_overwrite = true
  records         = [each.value.record_value]
  ttl             = 60
}

resource "fastly_tls_subscription_validation" "subscription" {
  depends_on      = [aws_route53_record.tls_validation]
  subscription_id = fastly_tls_subscription.subscription.id
}
