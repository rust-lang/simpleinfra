// Definition of the domain redirects we have.

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
