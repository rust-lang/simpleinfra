// This file configures index.crates.io

resource "aws_cloudfront_distribution" "index" {
  comment = var.index_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [var.index_domain_name]
  viewer_certificate {
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
  }

  default_cache_behavior {
    target_origin_id       = "main"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 60
    min_ttl     = 1
    max_ttl     = 31536000

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
    origin_id   = "main"
    domain_name = aws_s3_bucket.index.bucket_regional_domain_name
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

data "aws_route53_zone" "index" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.index_domain_name)), 0, 2)))
}

resource "aws_route53_record" "index" {
  zone_id = data.aws_route53_zone.index.id
  name    = var.index_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.index.domain_name]
}
