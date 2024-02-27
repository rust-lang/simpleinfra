locals {
  fastly_domain_name = "fastly-${var.static_domain_name}"

  primary_host_name  = aws_s3_bucket.static.region
  fallback_host_name = aws_s3_bucket.fallback.region

  dictionary_name = "compute_static"

  request_logs_endpoint = "request-logs"
  service_logs_endpoint = "service-logs"
}

data "aws_ssm_parameter" "datadog_token" {
  name = "/${var.env}/crates-io/fastly/datadog-token"
}

data "external" "package" {
  program     = ["bash", "terraform-external-build.sh"]
  working_dir = "./compute-static/bin"
}

data "fastly_package_hash" "package" {
  filename = data.external.package.result.path
}

resource "fastly_service_compute" "static" {
  name = var.static_domain_name

  domain {
    name = local.fastly_domain_name
  }

  domain {
    name = var.static_domain_name
  }

  backend {
    # Must be identical to s3-primary-host item in dictionary
    name = local.primary_host_name

    address       = aws_s3_bucket.static.bucket_regional_domain_name
    override_host = aws_s3_bucket.static.bucket_regional_domain_name

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = aws_s3_bucket.static.bucket_regional_domain_name
  }

  backend {
    # Must be identical to s3-fallback-host item in dictionary
    name = local.fallback_host_name

    address       = aws_s3_bucket.fallback.bucket_regional_domain_name
    override_host = aws_s3_bucket.fallback.bucket_regional_domain_name

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = aws_s3_bucket.fallback.bucket_regional_domain_name
  }

  dictionary {
    name = local.dictionary_name
  }

  package {
    filename         = data.external.package.result.path
    source_code_hash = data.fastly_package_hash.package.hash
  }

  logging_s3 {
    name        = "s3-${local.request_logs_endpoint}"
    bucket_name = aws_s3_bucket.logs.bucket

    s3_iam_role = aws_iam_role.fastly_assume_role.arn
    domain      = "s3.us-west-1.amazonaws.com"
    path        = "/fastly-requests/${var.static_domain_name}/"

    compression_codec = "zstd"
  }

  logging_s3 {
    name        = "s3-${local.service_logs_endpoint}"
    bucket_name = aws_s3_bucket.logs.bucket

    s3_iam_role = aws_iam_role.fastly_assume_role.arn
    domain      = "s3.us-west-1.amazonaws.com"
    path        = "/fastly-logs/${var.static_domain_name}/"

    compression_codec = "zstd"
  }

  logging_datadog {
    name  = "datadog-${local.request_logs_endpoint}"
    token = data.aws_ssm_parameter.datadog_token.value
  }
}

resource "fastly_service_dictionary_items" "compute_static" {
  for_each = {
    for d in fastly_service_compute.static.dictionary : d.name => d if d.name == local.dictionary_name
  }

  service_id    = fastly_service_compute.static.id
  dictionary_id = each.value.dictionary_id
  manage_items  = true

  items = {
    "cloudfront-url" : local.cloudfront_domain_name
    "datadog-request-logs-endpoint" : "datadog-${local.request_logs_endpoint}"
    "s3-fallback-host" : local.fallback_host_name
    "s3-primary-host" : local.primary_host_name
    "s3-request-logs-endpoint" : "s3-${local.request_logs_endpoint}"
    "s3-service-logs-endpoint" : "s3-${local.service_logs_endpoint}"
    "service-name" : var.static_domain_name
    "static-ttl" : var.static_ttl
  }
}

module "fastly_tls_subscription_globalsign" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.static.id

  domains = [
    local.fastly_domain_name,
    var.static_domain_name
  ]
}

resource "aws_route53_record" "fastly_static_domain" {
  name            = local.fastly_domain_name
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.static.id
  allow_overwrite = true
  records         = module.fastly_tls_subscription_globalsign.destinations
  ttl             = 60
}

resource "aws_route53_record" "weighted_static_fastly" {
  zone_id = data.aws_route53_zone.static.id
  name    = var.static_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_record.fastly_static_domain.fqdn]

  weighted_routing_policy {
    weight = var.static_fastly_weight
  }

  set_identifier = "fastly"
}
