provider "aws" {}
provider "aws" {
  alias = "east1"
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
