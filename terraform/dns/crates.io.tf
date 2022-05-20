// DNS records for the crates.io domain.
//
// Note that some of the records are managed by other Terraform resources, and
// thus are missing from this file!

module "crates_io" {
  source = "./impl"

  domain  = "crates.io"
  comment = "main domain for crates.io"
  ttl     = 300

  CNAME = {
    "status" = ["pvbm341xnpgm.stspg-customer.com"],
    "doc"    = ["rust-lang.github.io"], # https://github.com/rust-lang/cargo/tree/gh-pages
  }

  MX = {
    "@"    = local.mailgun_mx,
    "mail" = local.mailgun_mx,
  }

  TXT = {
    "@"                = [local.mailgun_spf],
    "mail"             = [local.mailgun_spf],
    "k1._domainkey"    = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+eQtAm5xohRQJCbwTQ8e27GhOdxji94CVOBXQtuiq75sEVu9nMImBiv8UOipvmiTFsM4Odnp7mIq8UeyPDpeUwtbPv9SYflEJt6o+Im5YOU/UnhEXqa1tXbpFrQSISVYz129G1SxGKMmxSBvyrjPNBJJOofqLHrIQrrdcgh5CywIDAQAB"],
    "mailo._domainkey" = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDu3zVBL/h7U1maoWkGJMi5Gd6OGhqsuBt19o3cRrkaxI1+XMJw9GIPXSc9BZZruVOICJ2Y1SJI2A2SPGIIa9CqYhlyPEcL5AvtoaORX+VjlsPXcdoUH4eX5fjjrWRn8PlWqBrILTRVkhMrz6luFMmzmmHpHC0WbwIQ7QZgnexn5wIDAQAB"],
    "_dmarc"           = ["v=DMARC1; p=none; rua=mailto:dmarc-rua@rust-lang.org; fo=1; ruf=mailto:dmarc-rua@rust-lang.org"],
  }
}
