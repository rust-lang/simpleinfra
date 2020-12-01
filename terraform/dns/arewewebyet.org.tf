// DNS records for the areweasyncyet.rs domain.

module "arewewebyet_org" {
  source = "./impl"

  domain  = "arewewebyet.org"
  comment = "domain for rust-lang/arewewebyet"
  ttl     = 300

  A = {
    "@" = local.github_pages_ipv4, # Defined in _shared.tf
  }

  CNAME = {
    "www" = ["rust-lang.github.io."],
  }
}
