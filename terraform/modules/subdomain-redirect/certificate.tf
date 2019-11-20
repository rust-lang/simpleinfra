locals {
  domain_names       = keys(var.from)
  main_domain_name   = local.domain_names[0]
  other_domain_names = slice(local.domain_names, 1, length(local.domain_names))
}

resource "aws_acm_certificate" "cert" {
  provider = aws.east1

  domain_name               = local.main_domain_name
  subject_alternative_names = local.other_domain_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = length(local.domain_names)

  zone_id = var.from[element(aws_acm_certificate.cert.domain_validation_options, count.index).domain_name]
  ttl     = 60

  # The element function is used here instead of the square brackets syntax
  # since the function is lazily evaluated. This is needed when adding a new
  # domain to an existing redirect, otherwise during the planning step
  # Terraform will error out.
  name    = element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_name
  type    = element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_type
  records = [element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_value]
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.east1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation[*].fqdn
}
