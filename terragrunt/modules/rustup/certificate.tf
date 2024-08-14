module "certificate" {
  source = "../acm-certificate"

  providers = {
    aws = aws.us-east-1
  }

  domains = [
    var.builds_domain_name,
  ]

  legacy = true
}
