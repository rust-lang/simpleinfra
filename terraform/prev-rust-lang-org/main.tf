data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_cloudfront_function" "prev_rust_lang_org_redirect" {
  name    = "prev-rust-lang-org-redirect"
  comment = "Redirect prev.rust-lang.org to rust-lang.org"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/prev_rust_lang_org_redirect.js")
}

resource "aws_cloudfront_distribution" "prev_rust_lang_org" {
  comment = "prev.rust-lang.org"

  enabled             = true
  wait_for_deployment = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2"
  default_root_object = ""

  aliases = [
    "prev.rust-lang.org",
  ]

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:890664054962:certificate/0633f4b2-8a1f-46f8-a2d3-184c461a2eb8"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior {
    target_origin_id       = "placeholder"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.prev_rust_lang_org_redirect.arn
    }
  }

  # CloudFront still requires a default origin, even though the viewer-request
  # function returns the redirect response before any origin fetch occurs.
  origin {
    origin_id   = "placeholder"
    domain_name = "example.com"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "prev_rust_lang_org" {
  zone_id = data.aws_route53_zone.rust_lang_org.zone_id
  name    = "prev.rust-lang.org"
  type    = "CNAME"
  ttl     = 10800
  records = [aws_cloudfront_distribution.prev_rust_lang_org.domain_name]
}
