module "certificate" {
  source = "../acm-certificate"

  providers = {
    aws = aws.us-east-1
  }

  domains = [
    var.webapp_domain_name,
    var.static_domain_name,
    var.index_domain_name,
    local.cloudfront_domain_name,
    local.cloudfront_index_domain_name,
    # TODO: Uncomment for phase 2
    # local.cloudfront_webapp_domain_name,
  ]

  legacy = true
}
