module "crates_io" {
  source = "./domain"

  domain  = "${local.cratesio.domain}"
  comment = "main domain for ${local.cratesio.domain}"
  ttl     = 300

  CNAME = {
    "status.${local.cratesio.domain}." = ["pvbm341xnpgm.stspg-customer.com"],
    "ping.${local.cratesio.domain}."   = ["status.ping.apex.sh"],
    # Source: https://github.com/rust-lang/cargo/tree/gh-pages
    "doc.${local.cratesio.domain}." = ["rust-lang.github.io"],
  }

  MX = {
    "${local.cratesio.domain}." = [
      "10 mxa.mailgun.org",
      "10 mxb.mailgun.org",
    ],
    "mail.${local.cratesio.domain}." = [
      "10 mxa.mailgun.org",
      "10 mxb.mailgun.org",
    ],
  }

  TXT = {
    "${local.cratesio.domain}." = [
      "v=spf1 include:mailgun.org ~all",
    ],
    "mail.${local.cratesio.domain}." = [
      "v=spf1 include:mailgun.org ~all",
    ],
    "k1._domainkey.${local.cratesio.domain}." = [
      "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+eQtAm5xohRQJCbwTQ8e27GhOdxji94CVOBXQtuiq75sEVu9nMImBiv8UOipvmiTFsM4Odnp7mIq8UeyPDpeUwtbPv9SYflEJt6o+Im5YOU/UnhEXqa1tXbpFrQSISVYz129G1SxGKMmxSBvyrjPNBJJOofqLHrIQrrdcgh5CywIDAQAB",
    ],
    "mailo._domainkey.${local.cratesio.domain}." = [
      "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDu3zVBL/h7U1maoWkGJMi5Gd6OGhqsuBt19o3cRrkaxI1+XMJw9GIPXSc9BZZruVOICJ2Y1SJI2A2SPGIIa9CqYhlyPEcL5AvtoaORX+VjlsPXcdoUH4eX5fjjrWRn8PlWqBrILTRVkhMrz6luFMmzmmHpHC0WbwIQ7QZgnexn5wIDAQAB",
    ]
  }
}
