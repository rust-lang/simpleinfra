data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "dev_desktop_us_2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-us-2.infra.rust-lang.org"
  type    = "A"
  # IPv4 address of dev-desktop-us-2 in GCP
  records = ["136.114.133.79"]
  ttl     = 60
}

resource "aws_route53_record" "dev_desktop_us_2_ipv6" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-us-2.infra.rust-lang.org"
  type    = "AAAA"
  # IPv6 address of dev-desktop-us-2 in GCP
  records = ["2600:1900:4001:42e:0:0:0:0"]
  ttl     = 60
}

resource "aws_route53_record" "dev_desktop_eu_2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-eu-2.infra.rust-lang.org"
  type    = "A"
  # IPv4 address of dev-desktop-eu-2 in GCP
  records = ["34.14.19.138"]
  ttl     = 60
}

resource "aws_route53_record" "dev_desktop_eu_2_ipv6" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop-eu-2.infra.rust-lang.org"
  type    = "AAAA"
  # IPv6 address of dev-desktop-eu-2 in GCP
  records = ["2600:1900:4010:3f81:0:0:0:0"]
  ttl     = 60
}
