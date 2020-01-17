// This file contains the definition of all the HTTP redirects from a subdomain
// we control to another URL. See the documentation for information on our
// setup, and how to make changes to it:
//
//    https://forge.rust-lang.org/infra/docs/dns.html
//

module "crates_io" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://crates.io"
  from = [
    "cratesio.com",
    "www.crates.io",
    "www.cratesio.com",
  ]
}

module "docs_rs" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://docs.rs"
  from = [
    "docsrs.com",
    "www.docs.rs",
    "www.docsrs.com",
  ]
}
