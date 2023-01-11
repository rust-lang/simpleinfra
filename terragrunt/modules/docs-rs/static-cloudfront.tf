// This file configures the static docs.rs CloudFront distribution.
//
// This distribution requires signed URLs for all queries, and serves files
// from the rust-docs-rs s3 bucket.

locals {
  static_domain_name = "static.${var.domain}"
}

module "static_certificate" {
  source = "../acm-certificate"

  domains = [
    local.static_domain_name
  ]

  legacy = false
}

resource "aws_cloudfront_cache_policy" "static_docs_rs" {
  name        = "static-docs-rs"
  default_ttl = 900 // 15 minutes
  min_ttl     = 0
  max_ttl     = 86400
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

data "aws_cloudfront_origin_request_policy" "s3cors" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "static_docs_rs"
  description                       = local.static_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static" {
  comment = local.static_domain_name

  enabled             = true
  wait_for_deployment = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = [local.static_domain_name]
  viewer_certificate {
    acm_certificate_arn      = module.static_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  origin {
    origin_id                = "s3"
    domain_name              = aws_s3_bucket.storage.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  default_cache_behavior {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.static_docs_rs.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.s3cors.id

    trusted_key_groups = []

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "static" {
  for_each = toset(["A", "AAAA"])
  zone_id  = var.zone_id
  name     = local.static_domain_name
  type     = each.value

  alias {
    name                   = aws_cloudfront_distribution.static.domain_name
    zone_id                = aws_cloudfront_distribution.static.hosted_zone_id
    evaluate_target_health = false
  }
}
