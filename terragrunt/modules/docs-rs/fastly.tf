data "external" "package" {
  program     = ["bash", "terraform-external-build.sh"]
  working_dir = "./fastly-compute-docs-rs/bin"
}

data "fastly_package_hash" "package" {
  filename = data.external.package.result.path
}

resource "fastly_configstore" "docs_rs" {
  name = local.config_store_name
}

resource "fastly_configstore_entries" "docs_rs" {
  store_id = fastly_configstore.docs_rs.id

  entries = {
    # https://www.fastly.com/documentation/guides/getting-started/hosts/shielding/
    # caveats:
    # https://www.fastly.com/documentation/guides/getting-started/hosts/shielding/#caveats-of-shielding
    # Our compute handler contains fallback logic in case of errors where we would directly
    # call the origin.
    # So if things break, just remove this entry.

    # this is the "san jose" shield location, closest to our EC2 server in AWS us-west1 (north california)
    # shield_pop = "sjc-ca-us"

    # max age for HSTS header.
    # should be less for test / staging environments
    hsts_max_age = "31557600"
  }

  # manage config entries only via terraform, manual changes will be overwritten on next apply
  manage_entries = true
}

resource "fastly_service_compute" "docs_rs" {
  name = var.cdn_domain_name

  domain {
    name = var.cdn_domain_name
  }

  backend {
    name = "docs_rs_origin"

    address       = var.cdn_origin
    override_host = var.cdn_origin

    between_bytes_timeout = 10000  # ms -> 10s
    connect_timeout       = 10000  # ms -> 10s
    first_byte_timeout    = 120000 # ms -> 120s -> same as origin
    keepalive_time        = 60     # s

    use_ssl = false
    port    = 80
  }

  resource_link {
    name        = local.secret_store_name
    resource_id = fastly_secretstore.docs_rs.id
  }

  resource_link {
    name        = local.config_store_name
    resource_id = fastly_configstore.docs_rs.id
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

module "fastly_tls_subscription_globalsign_docs_rs" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = var.zone_id

  domains = [
    var.cdn_domain_name,
  ]

  depends_on = [fastly_service_compute.docs_rs]
}

resource "aws_route53_record" "cdn_cname" {
  zone_id = var.zone_id
  name    = var.cdn_domain_name
  type    = "CNAME"
  ttl     = 60
  records = module.fastly_tls_subscription_globalsign_docs_rs.destinations
}
