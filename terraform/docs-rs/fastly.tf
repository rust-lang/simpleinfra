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

  # commenting this to avoid conflicts
  # TODO: uncomment this
  # domain {
  #   name = local.domain_name
  # }

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
    # TODO: uncomment this
    # local.domain_name
  ]

  depends_on = [fastly_service_compute.docs_rs]
}

resource "aws_route53_record" "fastly_domain" {
  name            = local.fastly_domain_name
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.webapp.id
  allow_overwrite = true
  records         = module.fastly_tls_subscription_globalsign.destinations
  ttl             = 60
}
