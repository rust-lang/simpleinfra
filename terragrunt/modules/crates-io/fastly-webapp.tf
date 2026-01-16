// This file configures the crates.io web app API via Fastly CDN

locals {
  fastly_webapp_domain_name = "fastly-app.${var.webapp_domain_name}"
}

resource "fastly_service_vcl" "webapp" {
  name = var.webapp_domain_name

  domain {
    name = local.fastly_webapp_domain_name
  }

  domain {
    name = var.webapp_domain_name
  }

  backend {
    name = "crates_io_webapp"

    address       = var.webapp_origin_domain
    override_host = var.webapp_origin_domain

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = var.webapp_origin_domain

    # crates.io accepts crate uploads, so add a longer origin timeout.
    first_byte_timeout    = local.webapp_cdn_timeout_seconds * 1000
    between_bytes_timeout = local.webapp_cdn_timeout_seconds * 1000
  }

  default_ttl = 0

  # Forward relevant headers to the origin
  snippet {
    name    = "forward headers to origin"
    type    = "miss"
    content = <<-VCL
      # Set the Host header for the backend
      set bereq.http.Host = "${var.webapp_origin_domain}";

      # Forward headers from the client request that the backend needs
      # See the cloudfront-webapp.tf for explanations of each header
      set bereq.http.Accept = req.http.Accept;
      set bereq.http.Accept-Encoding = req.http.Accept-Encoding;
      set bereq.http.Referer = req.http.Referer;
      set bereq.http.User-Agent = req.http.User-Agent;
      set bereq.http.X-Request-Id = req.http.X-Request-Id;
      set bereq.http.Authorization = req.http.Authorization;
      set bereq.http.Cookie = req.http.Cookie;
    VCL
  }

  # Pass all requests to origin (no caching for API)
  snippet {
    name    = "pass all requests"
    type    = "recv"
    content = <<-VCL
      # Don't cache any requests - pass directly to origin
      return(pass);
    VCL
  }

  # Handle HSTS headers if strict_security_headers is enabled
  dynamic "snippet" {
    for_each = var.strict_security_headers ? [1] : []
    content {
      name    = "add HSTS header"
      type    = "deliver"
      content = <<-VCL
        set resp.http.Strict-Transport-Security = "max-age=31536000; includeSubDomains";
      VCL
    }
  }
}

module "fastly_tls_subscription_webapp" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.webapp.id

  domains = [
    local.fastly_webapp_domain_name,
    var.webapp_domain_name
  ]
}

resource "aws_route53_record" "fastly_webapp_domain" {
  zone_id         = data.aws_route53_zone.webapp.id
  name            = local.fastly_webapp_domain_name
  type            = "CNAME"
  ttl             = 300
  allow_overwrite = true
  records         = module.fastly_tls_subscription_webapp.destinations
}

resource "aws_route53_record" "weighted_webapp_fastly" {
  for_each = toset(var.dns_apex ? [] : [""])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_record.fastly_webapp_domain.fqdn]

  weighted_routing_policy {
    weight = var.webapp_fastly_weight
  }

  set_identifier = "fastly"
}

resource "aws_route53_record" "weighted_webapp_fastly_apex" {
  for_each = toset(var.dns_apex ? ["A", "AAAA"] : [])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = each.value

  alias {
    # For apex domains with Fastly, we use the Fastly subdomain as the alias target
    name                   = aws_route53_record.fastly_webapp_domain.fqdn
    zone_id                = data.aws_route53_zone.webapp.zone_id
    evaluate_target_health = false
  }

  weighted_routing_policy {
    weight = var.webapp_fastly_weight
  }

  set_identifier = "fastly"
}
