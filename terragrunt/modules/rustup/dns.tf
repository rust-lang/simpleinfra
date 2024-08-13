data "aws_route53_zone" "builds" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.builds_domain_name)), 0, 2)))
}

resource "aws_route53_record" "cloudfront_builds_domain" {
  zone_id = data.aws_route53_zone.builds.id
  name    = var.builds_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.builds.domain_name]
}
