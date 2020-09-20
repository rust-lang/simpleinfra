// DNS records for the rustaceans.org domain.

module "rustaceans_org" {
  source = "./impl"

  domain  = "rustaceans.org"
  comment = "domain for nrc/rustaceans.org"
  ttl     = 300

  A = {
    "@" = ["161.35.234.130"],
  }

  CNAME = {
    "www" = ["rustaceans.org."],
  }
}

