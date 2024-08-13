resource "aws_cloudfront_distribution" "builds" {
  comment = var.builds_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  aliases = [
    var.builds_domain_name,
  ]

  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "builds"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

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
  }

  origin {
    origin_id                = "builds"
    domain_name              = aws_s3_bucket.builds.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.builds.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "builds" {
  name                              = "rustup-builds"
  description                       = var.builds_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
