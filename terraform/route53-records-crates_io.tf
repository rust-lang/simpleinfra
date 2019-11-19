// This file contains the DNS records for the crates.io domain.
// More DNS records might be managed by other files.

resource "aws_route53_record" "crates_io__mx" {
  for_each = toset(["crates.io.", "mail.crates.io."])

  zone_id = aws_route53_zone.crates_io.id
  name    = each.value
  type    = "MX"
  ttl     = 300
  records = [
    "10 mxa.mailgun.org",
    "10 mxb.mailgun.org",
  ]
}

resource "aws_route53_record" "crates_io__spf" {
  for_each = toset(["crates.io.", "mail.crates.io."])

  zone_id = aws_route53_zone.crates_io.id
  name    = each.value
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:mailgun.org ~all"]
}

resource "aws_route53_record" "crates_io__dkim" {
  zone_id = aws_route53_zone.crates_io.id
  name    = "k1._domainkey.crates.io."
  type    = "TXT"
  ttl     = 300
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+eQtAm5xohRQJCbwTQ8e27GhOdxji94CVOBXQtuiq75sEVu9nMImBiv8UOipvmiTFsM4Odnp7mIq8UeyPDpeUwtbPv9SYflEJt6o+Im5YOU/UnhEXqa1tXbpFrQSISVYz129G1SxGKMmxSBvyrjPNBJJOofqLHrIQrrdcgh5CywIDAQAB"]
}

resource "aws_route53_record" "mail_crates_io__dkim" {
  zone_id = aws_route53_zone.crates_io.id
  name    = "mailo._domainkey.crates.io."
  type    = "TXT"
  ttl     = 300
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDu3zVBL/h7U1maoWkGJMi5Gd6OGhqsuBt19o3cRrkaxI1+XMJw9GIPXSc9BZZruVOICJ2Y1SJI2A2SPGIIa9CqYhlyPEcL5AvtoaORX+VjlsPXcdoUH4eX5fjjrWRn8PlWqBrILTRVkhMrz6luFMmzmmHpHC0WbwIQ7QZgnexn5wIDAQAB"]
}

resource "aws_route53_record" "status_crates_io" {
  zone_id = aws_route53_zone.crates_io.id
  name    = "status.crates.io."
  type    = "CNAME"
  ttl     = 300
  records = ["pvbm341xnpgm.stspg-customer.com"]
}

resource "aws_route53_record" "ping_crates_io" {
  zone_id = aws_route53_zone.crates_io.id
  name    = "ping.crates.io."
  type    = "CNAME"
  ttl     = 300
  records = ["status.ping.apex.sh"]
}

resource "aws_route53_record" "doc_crates_io" {
  zone_id = aws_route53_zone.crates_io.id
  name    = "doc.crates.io."
  type    = "CNAME"
  ttl     = 300
  records = ["rust-lang.github.io"]
}
