module "certificate" {
  source = "../acm-certificate"

  providers = {
    aws = aws.us-east-1
  }

  domains = [
    var.domain_name,
  ]

  legacy = true
}
