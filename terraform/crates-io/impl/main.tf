terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.59"
      configuration_aliases = [aws.us-east-1]
    }
  }
}

module "certificate" {
  source = "../../shared/modules/acm-certificate"
  providers = {
    aws = aws.us-east-1
  }

  domains = [
    var.webapp_domain_name,
    var.static_domain_name,
  ]
}
