// This file contains the configuration of the domain names we manage.

resource "aws_route53_zone" "rust_lang_org" {
  name    = local.rustlang.domain
  comment = "main domain name for the project"
}

resource "aws_route53_zone" "docs_rs" {
  name    = local.docsrs.domain
  comment = "Not registered here, steve registered on netim"
}

// Below contains the definition of all the HTTP redirects from a subdomain
// we control to another URL. See the documentation for information on our
// setup, and how to make changes to it:
//
//    https://forge.rust-lang.org/infra/docs/dns.html
//

module "redirect_www_crates_io" {
  source = "./modules/subdomain-redirect"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://${local.cratesio.domain}"
  from = {
    "www.${local.cratesio.domain}" = module.dns.zone_crates_io,
    "cratesio.com"                 = module.dns.zone_cratesio_com,
    "www.cratesio.com"             = module.dns.zone_cratesio_com,
  }
}

module "redirect_docs_rs" {
  source = "./modules/subdomain-redirect"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  to = "https://${local.docsrs.domain}"
  from = {
    "www.${local.docsrs.domain}" = aws_route53_zone.docs_rs.id
    "docsrs.com"                 = module.dns.zone_docsrs_com,
    "www.docsrs.com"             = module.dns.zone_docsrs_com,
  }
}
