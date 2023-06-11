data "aws_route53_zone" "rust_lang_net" {
  name = "rust-lang.net"
}

resource "aws_route53_record" "docs_rs_staging" {
  zone_id = data.aws_route53_zone.rust_lang_net.zone_id
  name    = "docs-rs-staging.rust-lang.net"
  type    = "NS"
  ttl     = 3600
  records = [
    "ns-1654.awsdns-14.co.uk.",
    "ns-95.awsdns-11.com.",
    "ns-549.awsdns-04.net.",
    "ns-1057.awsdns-04.org.",
  ]
}

resource "aws_route53_record" "bors_staging" {
  zone_id = data.aws_route53_zone.rust_lang_net.zone_id
  name    = "bors-staging.rust-lang.net"
  type    = "NS"
  ttl     = 3600
  records = [
    "ns-1347.awsdns-40.org.",
    "ns-2007.awsdns-58.co.uk.",
    "ns-777.awsdns-33.net.",
    "ns-436.awsdns-54.com.",
  ]
}

resource "aws_route53_record" "bors_prod" {
  zone_id = data.aws_route53_zone.rust_lang_net.zone_id
  name    = "bors-prod.rust-lang.net"
  type    = "NS"
  ttl     = 3600
  records = [
    "ns-1427.awsdns-50.org.",
    "ns-1958.awsdns-52.co.uk.",
    "ns-674.awsdns-20.net.",
    "ns-410.awsdns-51.com.",
  ]
}
