// This file configures the static.docs.rs CloudFront distribution.
//
// This distribution requires signed URLs for all queries, and serves files
// from the rust-docs-rs s3 bucket.

module "static_certificate" {
  source = "../shared/modules/acm-certificate"

  providers = {
    aws = aws.east1
  }

  domains = [
    "static.docs.rs",
  ]
}

data "aws_cloudfront_cache_policy" "none" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "s3cors" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_public_key" "signer" {
  comment     = "static.docs.rs signing key"
  encoded_key = file("public_key.pem")
  name        = "static_docs_rs_key"
}

resource "aws_cloudfront_key_group" "signer" {
  comment = "static.docs.rs key group"
  items   = [aws_cloudfront_public_key.signer.id]
  name    = "static_docs_rs_keys"
}

resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "static_docs_rs"
  description                       = "static.docs.rs"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static" {
  comment = "static.docs.rs"

  enabled             = false
  wait_for_deployment = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = ["static.docs.rs"]
  viewer_certificate {
    acm_certificate_arn      = module.static_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  origin {
    origin_id                = "s3"
    domain_name              = "rust-docs-rs.s3.us-west-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  default_cache_behavior {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.none.id
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

  tags = {
    TeamAccess = "docs-rs"
  }
}

resource "aws_route53_record" "static" {
  for_each = toset(["A", "AAAA"])
  zone_id  = data.aws_route53_zone.static.id
  name     = "static.docs.rs"
  type     = each.value

  alias {
    name                   = aws_cloudfront_distribution.static.domain_name
    zone_id                = aws_cloudfront_distribution.static.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "static" {
  name = "docs.rs"
}
