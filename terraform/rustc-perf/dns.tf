data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "legacy" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "rustc-perf-legacy.infra.rust-lang.org"
  type    = "A"
  records = ["159.69.58.186"]
  ttl     = 300
}

resource "aws_route53_record" "one" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "rustc-perf-one.infra.rust-lang.org"
  type    = "A"
  records = ["144.76.186.39"]
  ttl     = 300
}

resource "aws_route53_record" "two" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "rustc-perf-two.infra.rust-lang.org"
  type    = "A"
  records = ["195.201.172.195"]
  ttl     = 300
}

resource "aws_route53_record" "m9g" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "rustc-perf-m9g.infra.rust-lang.org"
  type    = "A"
  records = ["18.227.166.169"]
  ttl     = 300
}

resource "aws_route53_record" "m9g_ipv6" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "rustc-perf-m9g.infra.rust-lang.org"
  type    = "AAAA"
  records = ["2600:1f16:84d:5800:af87:f3a1:da6c:819"]
  ttl     = 300
}
