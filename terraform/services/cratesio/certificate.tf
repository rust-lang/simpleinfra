// This file requests the TLS certificate used to serve all the
// crates.io-related CloudFront distributions.

resource "aws_acm_certificate" "cert" {
  provider = aws.east1

  domain_name               = var.webapp_domain_name
  subject_alternative_names = [var.static_domain_name]
  validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation_0" {
  zone_id = var.dns_zone
  ttl     = 60
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
}

resource "aws_route53_record" "cert_validation_1" {
  zone_id = var.dns_zone
  ttl     = 60
  name    = aws_acm_certificate.cert.domain_validation_options[1].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[1].resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options[1].resource_record_value]
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.east1

  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    aws_route53_record.cert_validation_0.fqdn,
    aws_route53_record.cert_validation_1.fqdn,
  ]
}
