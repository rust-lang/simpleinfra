locals {
  fastly_domain_name   = "fastly.${local.domain_name}"
  static_fastly_weight = 0
  secret_store_name    = "docs_rs_secrets"
}

data "external" "package" {
  program     = ["bash", "terraform-external-build.sh"]
  working_dir = "./fastly-compute-docs-rs/bin"
}

data "fastly_package_hash" "package" {
  filename = data.external.package.result.path
}

resource "fastly_service_compute" "docs_rs" {
  name = local.domain_name

  domain {
    name = local.fastly_domain_name
  }

  domain {
    name = local.domain_name
  }

  backend {
    name = "docs_rs_origin"

    address       = local.origin
    override_host = local.origin

    use_ssl = false
    port    = 80
  }

  resource_link {
    name        = "docs_rs_secrets"
    resource_id = fastly_secretstore.docs_rs.id
  }

  package {
    filename         = data.external.package.result.path
    source_code_hash = data.fastly_package_hash.package.hash
  }
}

# Values for secrets should be set manually in the Fastly web interface
resource "fastly_secretstore" "docs_rs" {
  name = local.secret_store_name
}

module "fastly_tls_subscription_globalsign" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.webapp.id

  domains = [
    local.fastly_domain_name,
  ]

  depends_on = [fastly_service_compute.docs_rs]
}

# I installed the same module twice because the first time I created it with just one domain
# and I can't edit it anymore.
module "fastly_tls_subscription_globalsign_docs_rs" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.webapp.id

  domains = [
    local.domain_name,
  ]

  depends_on = [fastly_service_compute.docs_rs]
}

resource "aws_route53_record" "fastly_domain" {
  name            = local.fastly_domain_name
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.webapp.id
  allow_overwrite = true
  records         = concat(module.fastly_tls_subscription_globalsign.destinations, module.fastly_tls_subscription_globalsign_docs_rs.destinations)
  ttl             = 60
}

data "fastly_tls_configuration" "docs_rs_tls" {
  id = module.fastly_tls_subscription_globalsign_docs_rs.tls_configuration_id
}

resource "aws_route53_record" "webapp_apex" {
  for_each = toset(["AAAA", "A"])
  zone_id  = data.aws_route53_zone.webapp.id
  name     = local.domain_name
  type     = each.value
  ttl      = 60

  records = [for dns_record in data.fastly_tls_configuration.docs_rs_tls.dns_records : dns_record.record_value if dns_record.record_type == each.value]
}
