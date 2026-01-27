locals {
  # Public CloudFront alias hostname.
  domain_name = "content.rust-lang.org"
}

resource "aws_route53_zone" "zone" {
  name = local.domain_name
}

# Create the DNS record pointing the domain to CloudFront.
resource "aws_route53_record" "public" {
  zone_id = aws_route53_zone.zone.id
  name    = local.domain_name
  type    = "A"

  # Use an alias record to point at the CloudFront distribution.
  alias {
    name                   = aws_cloudfront_distribution.public.domain_name
    zone_id                = aws_cloudfront_distribution.public.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "public_ipv6" {
  zone_id = aws_route53_zone.zone.id
  name    = local.domain_name
  type    = "AAAA"

  # Use an alias record to point at the CloudFront distribution.
  alias {
    name                   = aws_cloudfront_distribution.public.domain_name
    zone_id                = aws_cloudfront_distribution.public.hosted_zone_id
    evaluate_target_health = false
  }
}
