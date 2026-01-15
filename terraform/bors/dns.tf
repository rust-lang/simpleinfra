data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

# Point to the new bors
resource "aws_route53_record" "bors" {
  zone_id = data.aws_route53_zone.rust_lang_org.zone_id
  name    = "bors.rust-lang.org"
  type    = "CNAME"
  ttl     = 300
  records = ["bors-prod.rust-lang.net"]
}
