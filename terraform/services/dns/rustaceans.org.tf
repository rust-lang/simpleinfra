module "rustaceans_org" {
  source = "./domain"

  domain  = "rustaceans.org"
  comment = "domain for nrc/rustaceans.org"
  ttl     = 300

  A = {
    "@" = ["107.170.197.220"],
  }

  CNAME = {
    "www" = ["rustaceans.org."],
  }
}

