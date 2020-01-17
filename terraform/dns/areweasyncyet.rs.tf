// DNS records for the areweasyncyet.rs domain.

module "areweasyncyet_rs" {
  source = "./impl"

  domain  = "areweasyncyet.rs"
  comment = "domain for rust-lang/areweasyncyet.rs"
  ttl     = 300

  A = {
    "@" = local.github_pages_ipv4, # Defined in _shared.tf
  }
}
