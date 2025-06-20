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

output "rustc_perf_ips" {
  value = [
    tolist(aws_route53_record.legacy.records)[0],
    tolist(aws_route53_record.one.records)[0]
  ]
}
