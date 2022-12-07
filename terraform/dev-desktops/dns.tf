resource "aws_route53_record" "dev_desktop_eu_2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-eu-2.infra.rust-lang.org"
  type    = "CNAME"
  records = ["dev-desktop-eu-2.westeurope.cloudapp.azure.com"]
  ttl     = 60
}

resource "aws_route53_record" "dev_desktop_us_2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-us-2.infra.rust-lang.org"
  type    = "CNAME"
  records = ["dev-desktop-us-2.westus2.cloudapp.azure.com"]
  ttl     = 60
}
