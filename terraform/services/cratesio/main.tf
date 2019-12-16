provider "aws" {}
provider "aws" {
  alias = "east1"
}

module "certificate" {
  source = "../../modules/acm-certificate"
  providers = {
    aws = aws.east1
  }

  domains = {
    (var.webapp_domain_name) = var.dns_zone,
    (var.static_domain_name) = var.dns_zone,
  }
}
