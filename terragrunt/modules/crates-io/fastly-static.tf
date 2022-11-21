resource "fastly_service_vcl" "static" {
  name = var.static_domain_name

  domain {
    name = var.static_domain_name
  }

  backend {
    address       = aws_s3_bucket.static.bucket_regional_domain_name
    name          = aws_s3_bucket.static.region
    override_host = aws_s3_bucket.static.bucket_regional_domain_name

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = aws_s3_bucket.static.bucket_regional_domain_name
  }
}

resource "fastly_tls_subscription" "static" {
  certificate_authority = "lets-encrypt"
  domains               = [var.static_domain_name]
}

resource "aws_route53_record" "static_tls_validation" {
  depends_on = [fastly_tls_subscription.static]

  for_each = {
    for challenge in fastly_tls_subscription.static.managed_dns_challenges :
    trimprefix(challenge.record_name, "_acme-challenge.") => challenge
  }

  # only reads the first element in the list since all elements are exactly the same (see above)
  name            = each.value[0].record_name
  type            = each.value[0].record_type
  zone_id         = data.aws_route53_zone.static.id
  allow_overwrite = true
  records         = [each.value[0].record_value]
  ttl             = 60
}

resource "fastly_tls_subscription_validation" "static" {
  depends_on      = [aws_route53_record.static_tls_validation]
  subscription_id = fastly_tls_subscription.static.id
}
