// This file configures the crates.io web app API via CloudFront CDN

locals {
  cloudfront_webapp_domain_name = "cloudfront-app.${var.webapp_domain_name}"
  webapp_cdn_timeout_seconds    = 60
}

# Cache key for the web app distribution. Keep this minimal so CloudFront can
# share cached objects across viewers. Values that the origin needs but that
# must not fragment the cache are forwarded via the origin request policy below.
resource "aws_cloudfront_cache_policy" "webapp" {
  name = replace(var.webapp_domain_name, ".", "-")

  # default_ttl is used only when the origin omits Cache-Control/Expires, so
  # responses without caching headers are not cached. max_ttl caps the TTL for
  # the origin's immutable assets (Cache-Control: max-age=315360000) at 1 year.
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 31536000 // 1 year

  parameters_in_cache_key_and_forwarded_to_origin {
    # Cache Gzip and Brotli variants separately and let CloudFront compress at
    # the edge. This normalizes Accept-Encoding into the cache key, so the
    # header does not need to be forwarded to the origin explicitly.
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        // The crates.io website and API respond with different content based
        // on what the client is accepting (i.e. HTML, JSON...). CloudFront
        // ignores the origin's Vary header, so Accept must be part of the cache
        // key (not just forwarded) to avoid serving the wrong representation.
        items = ["Accept"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

# Headers, cookies, and query strings the origin needs but that must stay out of
# the cache key, so caching them does not fragment the cache across viewers.
resource "aws_cloudfront_origin_request_policy" "webapp" {
  name = replace(var.webapp_domain_name, ".", "-")

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        // The header needs to be forwarded so it can be stored in the logs and
        // analyzed for abuse prevention and rate limiting purposes.
        "Referer",
        // Users of the API are tracked based on the user agent, for abuse
        // prevention purposes. The header needs to be forwarded so we can
        // inspect it in the logs.
        "User-Agent",
        // Heroku will use an existing header if it is set by the client, so we
        // may want to forward it along at this layer as well. This might be
        // helpful for debugging at some point.
        "X-Request-Id",
        // Some authenticated API endpoints use the GET method, so we need to
        // forward the Authorization header to allow token authentication.
        "Authorization",
      ]
    }
  }

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "webapp" {
  comment = var.webapp_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  aliases = [
    local.cloudfront_webapp_domain_name,
    var.webapp_domain_name
  ]
  viewer_certificate {
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
  }

  default_cache_behavior {
    target_origin_id       = "heroku"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.webapp.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.webapp.id

    response_headers_policy_id = var.strict_security_headers ? aws_cloudfront_response_headers_policy.webapp[0].id : null
  }

  origin {
    origin_id   = "heroku"
    domain_name = var.webapp_origin_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]

      // crates.io accepts crate uploads, so add a longer origin timeout.
      origin_keepalive_timeout = local.webapp_cdn_timeout_seconds
      origin_read_timeout      = local.webapp_cdn_timeout_seconds
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    TeamAccess = "crates-io"
  }
}

resource "aws_route53_record" "cloudfront_webapp_domain" {
  zone_id = data.aws_route53_zone.webapp.id
  name    = local.cloudfront_webapp_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]
}

resource "aws_route53_record" "weighted_webapp_cloudfront" {
  for_each = toset(var.dns_apex ? [] : [""])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]

  weighted_routing_policy {
    weight = var.webapp_cloudfront_weight
  }

  set_identifier = "cloudfront"
}

data "aws_route53_zone" "webapp" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.webapp_domain_name)), 0, 2)))
}

resource "aws_route53_record" "weighted_webapp_cloudfront_apex" {
  for_each = toset(var.dns_apex ? ["A", "AAAA"] : [])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.webapp.domain_name
    zone_id                = aws_cloudfront_distribution.webapp.hosted_zone_id
    evaluate_target_health = false
  }

  weighted_routing_policy {
    weight = var.webapp_cloudfront_weight
  }

  set_identifier = "cloudfront"
}

# Set strict-transport-security headers for crates.io and its subdomains
# See https://github.com/rust-lang/crates.io/issues/5332 for details
resource "aws_cloudfront_response_headers_policy" "webapp" {
  count = var.strict_security_headers ? 1 : 0

  name = replace(var.webapp_domain_name, ".", "-")

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = false

      # Override the response header received from the origin
      override = true
    }
  }
}
