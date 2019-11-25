module "areweasyncyet_rs" {
  source = "./domain"

  domain  = "areweasyncyet.rs"
  comment = "domain for rust-lang/areweasyncyet.rs"
  ttl     = 300

  A = {
    "areweasyncyet.rs." = local.github_pages_ipv4,
  }
}
