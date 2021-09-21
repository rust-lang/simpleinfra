terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }
}

module "certificate" {
  source = "../../modules/acm-certificate"

  domains = [
    var.domain_name,
  ]
}

resource "aws_cloudfront_distribution" "website" {
  comment = "static website ${var.domain_name}"

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  aliases = [var.domain_name]
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

  dynamic "origin" {
    for_each = var.origin_access_identity == null ? toset([true]) : toset([])
    content {
      origin_id   = "main"
      domain_name = var.origin_domain_name
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
