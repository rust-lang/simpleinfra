data "aws_route53_zone" "rust_lang_net" {
  name = "rust-lang.net"
}

resource "aws_route53_record" "docs_rs_staging" {
  zone_id = data.aws_route53_zone.rust_lang_net.zone_id
  name    = "docs-rs-staging.rust-lang.net"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-1654.awsdns-14.co.uk.",
    "ns-95.awsdns-11.com.",
    "ns-549.awsdns-04.net.",
    "ns-1057.awsdns-04.org.",
  ]
}
