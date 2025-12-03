locals {
  domain_name    = "docs.rs"
  domain_is_apex = true
  origin         = "docsrs.infra.rust-lang.org"
}

module "certificate" {
  source = "../shared/modules/acm-certificate"

  providers = {
    aws = aws.east1
  }

  domains = [
    local.domain_name,
  ]
}

resource "random_password" "origin_auth" {
  length  = 32
  special = false
}

data "aws_route53_zone" "webapp" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", local.domain_name)), 0, 2)))
}
