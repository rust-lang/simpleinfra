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

module "rustconf_com" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://rustconf.com"
  from = [
    "www.rustconf.com"
  ]
}

module "arewewebyet_org" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://www.arewewebyet.org"
  from = [
    "arewewebyet.org"
  ]
}

// https://github.com/rust-lang/docs.rs/issues/1210
module "docs_rs_metadata" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://docs.rs/about/metadata"
  from = [
    "package.metadata.docs.rs",
  ]
}
