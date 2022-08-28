terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.28"
    }
  }
}

module "certificate" {
  source = "../../modules/acm-certificate"

  domains = [
    var.domain_name,
  ]
}

data "aws_cloudfront_cache_policy" "cache" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "website" {
  comment = "static website ${var.domain_name}"

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = [var.domain_name]
  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  default_cache_behavior {
    target_origin_id       = "main"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = data.aws_cloudfront_cache_policy.cache.id
    response_headers_policy_id = var.response_policy_id
  }

  dynamic "origin" {
    for_each = var.origin_access_identity == null ? toset([true]) : toset([])
    content {
      origin_id   = "main"
      domain_name = var.origin_domain_name
      origin_path = var.origin_path
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_protocol_policy = "https-only"
      }
    }
  }
  dynamic "origin" {
    for_each = var.origin_access_identity != null ? toset([true]) : toset([])
    content {
      origin_id   = "main"
      domain_name = var.origin_domain_name

      s3_origin_config {
        origin_access_identity = var.origin_access_identity
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_route53_zone" "zone" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.domain_name)), 0, 2)))
}

resource "aws_route53_record" "website" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.website.domain_name]
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.website.arn
}
