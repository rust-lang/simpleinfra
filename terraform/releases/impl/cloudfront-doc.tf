module "lambda_doc_router" {
  source = "../../shared/modules/lambda"
  providers = {
    aws = aws.east1
  }

  name       = "${var.bucket}--doc-router"
  source_dir = "impl/lambdas/doc-router"
  handler    = "index.handler"
  runtime    = "nodejs12.x"
  role_arn   = data.aws_iam_role.cloudfront_lambda.arn
}

resource "aws_cloudfront_distribution" "doc" {
  comment = var.doc_domain_name

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [var.doc_domain_name]
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

    forwarded_values {
      headers      = []
      query_string = false
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda_doc_router.version_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern     = "*.woff2"
    cache_policy_id  = "cache-immutable"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "main"

    forwarded_values {
      headers      = []
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    origin_id   = "main"
    domain_name = aws_s3_bucket.static.website_endpoint
    origin_path = "/doc"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_route53_zone" "doc" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.doc_domain_name)), 0, 2)))
}

resource "aws_route53_record" "doc" {
  zone_id = data.aws_route53_zone.doc.id
  name    = var.doc_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.doc.domain_name]
}
