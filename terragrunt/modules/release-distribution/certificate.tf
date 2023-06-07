module "certificate" {
  source = "../acm-certificate"

  providers = {
    aws = aws.east1
  }

  domains = [
    var.doc_domain_name,
    var.static_domain_name,
    local.cloudfront_domain_name,
  ]

  legacy = true
}
