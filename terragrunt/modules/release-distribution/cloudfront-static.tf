module "lambda_static" {
  source = "../aws-lambda"
  providers = {
    aws = aws.east1
  }

  name       = "${local.name}--static-router"
  source_dir = "lambdas/static-router"
  handler    = "index.handler"
  runtime    = "nodejs16.x"
  role_arn   = data.aws_iam_role.cloudfront_lambda.arn
}

locals {
  cloudfront_domain_name = "cloudfront-${var.static_domain_name}"
}

resource "aws_cloudfront_distribution" "static" {
  comment = var.static_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  aliases = [
    local.cloudfront_domain_name,
    var.static_domain_name,
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

    default_ttl = var.static_ttl

    forwarded_values {
      headers = [
        // Following the spec, AWS S3 only replies with the CORS headers when
        // an Origin is present, and varies its response based on that. If we
        // don't forward the header CloudFront is going to cache the first CORS
        // response it receives, even if it's empty.
        "Origin",
      ]
      // Forwarding the query string is needed to make the file listing work:
      // list-files.html requests the directory content with the ?prefix=/foo
      // query string, and if the query string is not forwarded S3 will return
      // the same data forever, causing a loop in the JS.
      query_string = true
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda_static.version_arn
      include_body = false
    }
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 404
    response_page_path    = "/doc/nightly/not_found.html"
  }

  origin {
    origin_id   = "main"
    domain_name = data.aws_s3_bucket.static.bucket_regional_domain_name
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = data.aws_s3_bucket.logs.bucket_regional_domain_name
    prefix          = "cloudfront/${var.static_domain_name}"
  }
}

resource "aws_route53_record" "cloudfront_static_domain" {
  zone_id = data.aws_route53_zone.static.id
  name    = local.cloudfront_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.static.domain_name]
}

resource "aws_route53_record" "static" {
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
