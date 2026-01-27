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
  ttl     = 300
  # TODO Point the record at the distribution hostname.
  records = ["rust-lang.org"]
}
