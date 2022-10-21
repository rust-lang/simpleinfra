// This file configures crates.io

resource "aws_cloudfront_distribution" "webapp" {
  comment = var.webapp_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  aliases = [var.webapp_domain_name]
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

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 31536000 // 1 year

    response_headers_policy_id = var.strict_security_headers ? aws_cloudfront_response_headers_policy.webapp[0].id : null

    forwarded_values {
      headers = [
        // The crates.io website and API respond with different content based
        // on what the client is accepting (i.e. HTML, JSON...)
        "Accept",
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
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  // Cache assets ignoring headers, query strings and cookies.
  ordered_cache_behavior {
    path_pattern           = "/assets"
    target_origin_id       = "heroku"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers      = []
      query_string = false
      cookies {
        forward = "none"
      }
    }
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
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
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

resource "aws_route53_record" "webapp" {
  for_each = toset(var.dns_apex ? [] : [""])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]
}

data "aws_route53_zone" "webapp" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.webapp_domain_name)), 0, 2)))
}

resource "aws_route53_record" "webapp_apex" {
  for_each = toset(var.dns_apex ? ["A", "AAAA"] : [])

  zone_id = data.aws_route53_zone.webapp.id
  name    = var.webapp_domain_name
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.webapp.domain_name
    zone_id                = aws_cloudfront_distribution.webapp.hosted_zone_id
    evaluate_target_health = false
  }
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
