# The Fastly service must be deployed in two steps, since some resources depend
# on attributes that are only known after an `apply`. To deploy the service,
# comment out everything in Stage 2 and then run `terragrunt apply`. After the
# run has finished, uncomment Stage 2 and run `terragrunt apply` again.

locals {
  fastly_domain_name = "fastly-${var.static_domain_name}"

  primary_host_name  = aws_s3_bucket.static.region
  fallback_host_name = aws_s3_bucket.fallback.region

  dictionary_name = "compute_static"

  request_logs_endpoint = "s3-request-logs"
  service_logs_endpoint = "s3-service-logs"
}

data "external" "package" {
  program     = ["bash", "terraform-external-build.sh"]
  working_dir = "./compute-static/bin"
}

### Stage 1

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
    source_code_hash = filesha512(data.external.package.result.path)
  }

  logging_s3 {
    name        = local.request_logs_endpoint
    bucket_name = aws_s3_bucket.logs.bucket

    s3_iam_role = aws_iam_role.fastly_assume_role.arn
    domain      = "s3.us-west-1.amazonaws.com"
    path        = "/fastly-requests/${var.static_domain_name}/"
  }

  logging_s3 {
    name        = local.service_logs_endpoint
    bucket_name = aws_s3_bucket.logs.bucket

    s3_iam_role = aws_iam_role.fastly_assume_role.arn
    domain      = "s3.us-west-1.amazonaws.com"
    path        = "/fastly-logs/${var.static_domain_name}/"
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
    "s3-primary-host" : local.primary_host_name
    "s3-fallback-host" : local.fallback_host_name
    "static-ttl" : var.static_ttl
    "request-logs-endpoint" : local.request_logs_endpoint
    "service-logs-endpoint" : local.service_logs_endpoint
  }
}

resource "fastly_tls_subscription" "static" {
  certificate_authority = "lets-encrypt"
  domains = [
    local.fastly_domain_name,
    var.static_domain_name
  ]
}

### Stage 2

resource "aws_route53_record" "static_tls_validation" {
  depends_on = [fastly_tls_subscription.static]

  for_each = {
    for challenge in fastly_tls_subscription.static.managed_dns_challenges :
    trimprefix(challenge.record_name, "_acme-challenge.") => challenge
  }

  name            = each.value.record_name
  type            = each.value.record_type
  zone_id         = data.aws_route53_zone.static.id
  allow_overwrite = true
  records         = [each.value.record_value]
  ttl             = 60
}

resource "fastly_tls_subscription_validation" "static" {
  depends_on      = [aws_route53_record.static_tls_validation]
  subscription_id = fastly_tls_subscription.static.id
}

locals {
  # It is currently not possible to get the CNAME for TLS-enabled hostnames as a
  # Terraform resource. But the ACME HTTP challenge redirects production traffic
  # to Fastly, for which it uses the CNAME that we are looking for.
  #
  # The below snippet is a hack to get the CNAME for the static domain from the
  # HTTP challenge, until Fastly exposes it in the Terraform provider.
  fastly_static_destinations = flatten([
    for record in fastly_tls_subscription.static.managed_http_challenges :
    record.record_values if record.record_type == "CNAME"
  ])
}

resource "aws_route53_record" "fastly_static_domain" {
  name            = local.fastly_domain_name
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.static.id
  allow_overwrite = true
  records         = local.fastly_static_destinations
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
