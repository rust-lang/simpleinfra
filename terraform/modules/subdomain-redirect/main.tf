locals {
  url_hash     = substr(sha1(var.to), 0, 7)
  apex_domains = { for d, z in var.from : d => z if length(split(".", d)) <= 2 }
  subdomains   = { for d, z in var.from : d => z if length(split(".", d)) > 2 }
}

provider "aws" {}
provider "aws" {
  alias = "east1"
}

module "certificate" {
  source = "../acm-certificate"
  providers = {
    aws = aws.east1
  }

  domains = var.from
}

resource "aws_s3_bucket" "redirect" {
  bucket = "rust-http-redirect-${local.url_hash}"
  acl    = "public-read"

  website {
    redirect_all_requests_to = var.to
  }
}

resource "aws_cloudfront_distribution" "redirect" {
  comment = "redirect to ${var.to}"

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"

  aliases = keys(var.from)
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
    domain_name = aws_s3_bucket.redirect.website_endpoint

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

resource "aws_route53_record" "redirect_subdomain" {
  for_each = local.subdomains

  zone_id = each.value
  name    = each.key
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.redirect.domain_name]
}

resource "aws_route53_record" "redirect_apex_a" {
  for_each = local.apex_domains

  zone_id = each.value
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect_apex_aaaa" {
  for_each = local.apex_domains

  zone_id = each.value
  name    = each.key
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
