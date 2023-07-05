// This file configures static.crates.io

locals {
  cloudfront_domain_name = "cloudfront-${var.static_domain_name}"
}

resource "aws_cloudfront_function" "static_router" {
  name    = "${replace(var.static_domain_name, ".", "-")}--static-router"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("${path.module}/cloudfront-functions/static-router.js")
}

resource "aws_cloudfront_distribution" "static" {
  comment = var.static_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [
    local.cloudfront_domain_name,
    var.static_domain_name
  ]

  viewer_certificate {
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
  }

  default_cache_behavior {
    target_origin_id       = "main-with-fallback"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = var.static_ttl

    forwarded_values {
      headers = [
        // Following the spec, AWS S3 only replies with the CORS headers when
        // an Origin is present, and varies its response based on that. If we
        // don't forward the header CloudFront is going to cache the first CORS
        // response it receives, even if it's empty.
        "Origin",
      ]
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.static_router.arn
    }
  }

  origin {
    origin_id   = "main"
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
  }

  origin {
    origin_id   = "fallback"
    domain_name = aws_s3_bucket.fallback.bucket_regional_domain_name
  }

  origin_group {
    origin_id = "main-with-fallback"

    failover_criteria {
      status_codes = [500, 502, 503]
    }

    member {
      origin_id = "main"
    }

    member {
      origin_id = "fallback"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_regional_domain_name
    prefix          = "cloudfront/${var.static_domain_name}"
  }

  tags = {
    TeamAccess = "crates-io"
  }
}

data "aws_route53_zone" "static" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.static_domain_name)), 0, 2)))
}

resource "aws_route53_record" "cloudfront_static_domain" {
  zone_id = data.aws_route53_zone.static.id
  name    = local.cloudfront_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.static.domain_name]
}

resource "aws_route53_record" "weighted_static_cloudfront" {
  zone_id = data.aws_route53_zone.static.id
  name    = var.static_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_record.cloudfront_static_domain.fqdn]

  weighted_routing_policy {
    weight = var.static_cloudfront_weight
  }

  set_identifier = "cloudfront"
}
