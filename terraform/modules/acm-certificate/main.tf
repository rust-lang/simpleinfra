locals {
  top_level_domains = { for domain in var.domains : domain => join(".", reverse(slice(reverse(split(".", domain)), 0, 2))) }
}

data "aws_route53_zone" "zones" {
  for_each = toset(values(local.top_level_domains))
  name     = each.value
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domains[0]
  subject_alternative_names = slice(var.domains, 1, length(var.domains))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = length(var.domains)

  ttl = 60

  # The element function is used here instead of the square brackets syntax
  # since the function is lazily evaluated. This is needed when adding a new
  # domain to an existing certificate, otherwise during the planning step
  # Terraform will error out.
  name    = element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_name
  type    = element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_type
  records = [element(aws_acm_certificate.cert.domain_validation_options, count.index).resource_record_value]
  zone_id = data.aws_route53_zone.zones[local.top_level_domains[element(aws_acm_certificate.cert.domain_validation_options, count.index).domain_name]].id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation[*].fqdn
}
