// DNS records for the rustconf.com domain.
//
// Note that some of the records are managed by other Terraform resources, and
// thus are missing from this file!

module "rustconf_com" {
  source = "./impl"

  domain  = "rustconf.com"
  comment = "Main domain for RustConf"
  ttl     = 300

  A = {
    "@" = local.github_pages_ipv4,
  }

  CNAME = {
    "2016" = ["tildeio.github.io"],
    "2017" = ["tildeio.github.io"],
    "2018" = ["tildeio.github.io"],
    "2019" = ["tildeio.github.io"],
    "2020" = ["tildeio.github.io"],
    "cfp"  = ["cfp.rustconf.com.herokudns.com"],
  }

  MX = {
    "@" = local.mailgun_mx,
  }

  TXT = {
    "@"             = [local.mailgun_spf],
    "k1._domainkey" = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC6AVUUbCl/Ofx/ceeWryb4v//f/Sr5UGrRt4ibA4UY2JQ3Db++KEBsdur5qAxC9eiWeAbYQyfQhFGagbmLjyxd1eNepzAIPesz81U0hodsLCaKs7OHkLrQJcTRxVYwucL5rBXVLdAhg7A1veVeN1xiqh8HmEull5vYsmOknf6mtwIDAQAB"],
  }
}
