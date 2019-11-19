// This file contains the configuration of the domain names we manage.

resource "aws_route53_zone" "rust_lang_org" {
  name    = "rust-lang.org"
  comment = "main domain name for the project"
}

