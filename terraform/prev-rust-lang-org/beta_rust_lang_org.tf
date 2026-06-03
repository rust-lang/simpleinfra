resource "aws_route53_record" "beta_rust_lang_org" {
  zone_id = data.aws_route53_zone.rust_lang_org.zone_id
  name    = "beta.rust-lang.org"
  type    = "CNAME"
  ttl     = 10800
  records = [aws_cloudfront_distribution.beta_rust_lang_org.domain_name]
}

resource "aws_cloudfront_distribution" "beta_rust_lang_org" {
  comment = "beta.rust-lang.org"

  enabled             = true
  wait_for_deployment = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2"
  default_root_object = ""

  aliases = [
    "beta.rust-lang.org",
  ]

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:890664054962:certificate/0633f4b2-8a1f-46f8-a2d3-184c461a2eb8"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "S3-redirect"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  origin {
    origin_id   = "S3-redirect"
    domain_name = "rust-lang.org.s3-website-us-west-1.amazonaws.com"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
