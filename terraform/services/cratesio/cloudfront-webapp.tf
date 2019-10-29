// This file configures crates.io

resource "aws_cloudfront_distribution" "webapp" {
  comment = "${var.webapp_domain_name}"

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [var.webapp_domain_name]
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
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

    forwarded_values {
      headers      = ["Accept", "User-Agent"]
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
}

resource "aws_route53_record" "webapp" {
  zone_id = var.dns_zone
  name    = var.webapp_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.webapp.domain_name]
}
