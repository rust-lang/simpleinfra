terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.59"
      configuration_aliases = [aws.east1]
    }
  }
}

module "certificate" {
  source = "../../modules/acm-certificate"
  providers = {
    aws = aws.east1
  }

  domains = [
    var.webapp_domain_name,
    var.static_domain_name,
  ]
}
