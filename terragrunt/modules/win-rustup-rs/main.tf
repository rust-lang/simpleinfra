locals {
  human_readable_name = replace(var.domain_name, ".", "-")
}

resource "aws_cloudfront_response_headers_policy" "content_disposition" {
  name    = local.human_readable_name
  comment = "Set the Content-Disposition header for ${var.domain_name}"

  custom_headers_config {
    items {
      header   = "Content-Disposition"
      value    = "attachment; filename=\"rustup-init.exe\""
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  comment = var.domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  aliases = [
    var.domain_name,
  ]

  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "main"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    response_headers_policy_id = aws_cloudfront_response_headers_policy.content_disposition.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.origin_request.version_arn
      include_body = false
    }
  }

  origin {
    origin_id   = "main"
    domain_name = data.aws_s3_bucket.static.bucket_regional_domain_name
    origin_path = "/rustup/dist"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
