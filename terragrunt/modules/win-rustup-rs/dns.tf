resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.rustup.id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.distribution.domain_name]
}
