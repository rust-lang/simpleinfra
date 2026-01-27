locals {
  # The legacy account has zones for top-level domains (e.g. crates.io), while
  # new accounts have zones for subdomains (e.g. staging.crates.io).
  depth = var.legacy ? 2 : 3

  top_level_domains = { for domain in var.domains : domain => join(".", reverse(slice(reverse(split(".", domain)), 0, local.depth))) }

  zone_ids = merge(
    # Prefer explicit zone IDs passed to the module.
    var.zone_ids,
    # Fall back to looked-up zone IDs for any remaining zones.
    { for name, zone in data.aws_route53_zone.zones : name => zone.id }
  )
}

data "aws_route53_zone" "zones" {
  for_each = toset([
    for name in values(local.top_level_domains) : name
    # Skip lookups when a zone ID override was provided.
    if !contains(keys(var.zone_ids), name)
  ])
  name = each.value
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domains[0]
  subject_alternative_names = slice(var.domains, 1, length(var.domains))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# We use DNS records to prove to ACM that we control the domains we're getting certs for
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      # Use the explicit zone ID when provided, otherwise the lookup result.
      zone_id = local.zone_ids[local.top_level_domains[dvo.domain_name]]
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
