// This file configures the docs.rs CloudFront distribution.

locals {
  domain_name    = "docs.rs"
  domain_is_apex = true
  origin         = "docsrs.infra.rust-lang.org"
}

module "certificate" {
  source = "../shared/modules/acm-certificate"

  providers = {
    aws = aws.east1
  }

  domains = [
    local.domain_name,
  ]
}

resource "aws_cloudfront_cache_policy" "docs_rs" {
  name = "docs-rs"

  default_ttl = 31536000 // 1 year
  min_ttl     = 0
  max_ttl     = 31536000 // 1 year

  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          // Allow detecting HTTPS from the webapp
          "CloudFront-Forwarded-Proto",
          // Allow detecting the domain name from the webapp
          "Host",
        ]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "docs_rs" {
  name = "docs-rs"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["User-Agent"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "webapp" {
  comment = local.domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = [local.domain_name]
  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "ec2"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.docs_rs.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.docs_rs.id
  }

  origin {
    origin_id   = "ec2"
    domain_name = local.origin

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Auth"
      value = "some_secret_value"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // Stop CloudFront from caching error responses.
  //
  // Before we did this users were seeing error pages even after we resolved
  // outages, forcing us to invalidate the caches every time. The team agreed
  // the best solution was instead to stop CloudFront from caching error
  // responses altogether.
  dynamic "custom_error_response" {
    for_each = toset([400, 403, 404, 405, 414, 500, 501, 502, 503, 504])
    content {
      error_code            = custom_error_response.value
      error_caching_min_ttl = 0
    }
  }

  tags = {
    TeamAccess = "docs-rs"
  }
}

resource "aws_route53_record" "webapp" {
  for_each = toset(local.domain_is_apex ? [] : [""])

  zone_id = data.aws_route53_zone.webapp.id
  name    = local.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]
}

data "aws_route53_zone" "webapp" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", local.domain_name)), 0, 2)))
}

resource "aws_route53_record" "webapp_apex" {
  for_each = toset(local.domain_is_apex ? ["A", "AAAA"] : [])

  zone_id = data.aws_route53_zone.webapp.id
  name    = local.domain_name
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.webapp.domain_name
    zone_id                = aws_cloudfront_distribution.webapp.hosted_zone_id
    evaluate_target_health = false
  }
}
