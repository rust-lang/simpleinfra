locals {
  // Split the source domain names in two lists: one for the ones with a
  // subdomain, and one for the ones without ("apex domains"). This will be
  // used to create the proper DNS records.
  apex_domains = [for d in var.from : d if length(split(".", d)) <= 2]
  subdomains   = [for d in var.from : d if length(split(".", d)) > 2]

  // Map of the source domain names and the corresponding top-level domain,
  // used to retrieve the correct DNS Zone ID. For example, assuming the list
  // of source domains is the following:
  //
  //    ["foo.bar.com", "bar.com", "foo.bar.baz.com"]
  //
  // The content of the variable will be:
  //
  //    {
  //      "foo.bar.com"     = "bar.com",
  //      "bar.com"         = "baz.com",
  //      "foo.bar.baz.com" = "baz.com",
  //    }
  //
  top_level_domains = { for domain in var.from : domain => join(".", reverse(slice(reverse(split(".", domain)), 0, 2))) }
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.64"
      configuration_aliases = [aws.east1]
    }
  }
}

// Terraform boilerplate to define two connections to AWS: one for our default
// region (us-west-1) and one for the us-east-1 region. Users of the module
// are going to then forward the already-configured providers to it.

// S3 bucket used to perform the actual redirect when request comes in, thanks
// to S3's static website hosting feature. The name of the bucket contains the
// URL hash, to avoid collisions.

resource "aws_s3_bucket" "redirect" {
  bucket = "rust-http-redirect-${substr(sha1("${var.to_host}|${var.to_path}"), 0, 7)}"
  acl    = "public-read"

  website {
    # If redirect_all_requests_to (which conflicts with routing_rules and
    # doesn't allow choosing the response code) is not present AWS requires
    # index_document to be present unfortunately.
    #
    # This object is missing from the bucket, but it shouldn't matter as the
    # routing_rules below unconditionally redirects all requests
    index_document = "missing-object-but-this-field-is-required-by-s3"

    routing_rules = jsonencode([
      {
        Redirect = {
          HostName             = var.to_host
          ReplaceKeyPrefixWith = var.to_path
          Protocol             = "https"
          HttpRedirectCode     = var.permanent ? "301" : "302"
        }
      }
    ])
  }
}

// CloudFront distribution used to cache the redirects near the users and to
// add HTTPS support (S3 static websites are only available through HTTP).

module "certificate" {
  source = "../../shared/modules/acm-certificate"
  providers = {
    aws = aws.east1
  }

  domains = var.from
}

resource "aws_cloudfront_distribution" "redirect" {
  comment = "redirect to https://${var.to_host}/${var.to_path}"

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"

  aliases = var.from
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

// Create the DNS records for the source domain names.
//
// - For the ones with a subdomain, a standard CNAME record will be creatated.
// - For the ones without a subdomain (like example.com or rust-lang.org), an
//   ALIAS will be created for both IPv4 (A) and IPv6 (AAAA).

data "aws_route53_zone" "zones" {
  for_each = toset(values(local.top_level_domains))
  name     = each.value
}

resource "aws_route53_record" "redirect_subdomain" {
  for_each = toset(local.subdomains)

  zone_id = data.aws_route53_zone.zones[local.top_level_domains[each.value]].id
  name    = each.key
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.redirect.domain_name]
}

resource "aws_route53_record" "redirect_apex_a" {
  for_each = toset(local.apex_domains)

  zone_id = data.aws_route53_zone.zones[local.top_level_domains[each.value]].id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect_apex_aaaa" {
  for_each = toset(local.apex_domains)

  zone_id = data.aws_route53_zone.zones[local.top_level_domains[each.value]].id
  name    = each.key
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.redirect.domain_name
    zone_id                = aws_cloudfront_distribution.redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
