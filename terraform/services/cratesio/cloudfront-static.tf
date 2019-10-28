// This file configures static.crates.io

resource "aws_cloudfront_distribution" "static" {
  comment = "${var.static_domain_name}"

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [var.static_domain_name]
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  default_cache_behavior {
    target_origin_id       = "main"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    // Override any cache-related header, and cache for 10 years Most of the
    // content on static.crates.io is static (doh), so this is safe to do. For
    // content that change over time there are other cache behaviors below that
    // override this.
    default_ttl = 315360000
    min_ttl     = 315360000
    max_ttl     = 315360000

    forwarded_values {
      headers      = []
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/db-dump.tar.gz"
    target_origin_id       = "main"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    // Override any cache-related header, and never cache this file. Database
    // dumps are updated daily, and caching them might result in stale data
    // being returned. They're usually requested by batch jobs on other people'
    // servers so disabling CloudFront edge caching is not going to affect them
    // that much.
    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      headers      = []
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    origin_id   = "main"
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "website" {
  zone_id = var.dns_zone
  name    = var.static_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.static.domain_name]
}
