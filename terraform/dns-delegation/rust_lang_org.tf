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

# Plumbing subdomain used to enable email routing to
# Google mail servers, at least while MX records
# for rust-lang.org point to mailgun servers
resource "aws_route53_record" "gws_mx_records" {
  zone_id = data.aws_route53_zone.rust_lang_org.zone_id
  name    = "mail.rust-lang.org"
  type    = "MX"
  ttl     = 3600

  records = [
    "1 aspmx.l.google.com",
    "5 alt1.aspmx.l.google.com",
    "5 alt2.aspmx.l.google.com",
    "10 alt3.aspmx.l.google.com",
    "10 alt4.aspmx.l.google.com",
  ]
}
