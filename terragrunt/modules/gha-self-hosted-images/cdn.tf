locals {
  domain_name = "gha-self-hosted-images.infra.rust-lang.org"
}

resource "aws_cloudfront_distribution" "cdn" {
  comment = local.domain_name
  aliases = [local.domain_name]

  enabled             = true
  wait_for_deployment = false
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = module.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  default_cache_behavior {
    target_origin_id       = "s3"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    // We are serving pre-compressed VM disk images. Enabling CloudFront compression will just slow
    // things down needlessly.
    compress = false

    # Cache all objects for a year
    min_ttl     = 31536000
    max_ttl     = 31536000
    default_ttl = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern = "latest"

    target_origin_id       = "s3"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    # Cache the version pointer just for a minute
    min_ttl     = 60
    max_ttl     = 60
    default_ttl = 60

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    origin_id                = "s3"
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "cdn" {
  name = "gha-self-hosted-images"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "certificate" {
  source = "../acm-certificate"
  providers = {
    aws = aws.us-east-1
  }

  domains = [local.domain_name]
  legacy  = true
}

data "aws_route53_zone" "zone" {
  // Get the second-level domain name.
  name = join(".", reverse(slice(reverse(split(".", local.domain_name)), 0, 2)))
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.zone.id
  name    = local.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cdn.domain_name]
}
