data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "content" {
  zone_id = data.aws_route53_zone.rust_lang_org.zone_id
  name    = "content.rust-lang.org"
  type    = "NS"
  ttl     = 3600
  records = [
    "ns-336.awsdns-42.com.",
    "ns-1888.awsdns-44.co.uk.",
    "ns-697.awsdns-23.net.",
    "ns-1408.awsdns-48.org.",
  ]
}
