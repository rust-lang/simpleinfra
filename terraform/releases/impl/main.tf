terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.20"
      configuration_aliases = [aws.east1]
    }
  }
}

data "aws_iam_role" "cloudfront_lambda" {
  name = "cloudfront-lambda"
}

module "certificate" {
  source = "../../shared/modules/acm-certificate"
  providers = {
    aws = aws.east1
  }

  domains = [
    var.doc_domain_name,
    var.static_domain_name,
  ]
}
