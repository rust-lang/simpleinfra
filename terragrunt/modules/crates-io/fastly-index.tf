locals {
  fastly_index_domain_name = "fastly-${var.index_domain_name}"
}

resource "fastly_service_vcl" "index" {
  name = var.index_domain_name

  domain {
    name = local.fastly_index_domain_name
  }

  domain {
    name = var.index_domain_name
  }

  backend {
    name = aws_s3_bucket.index.bucket

    address       = aws_s3_bucket.index.bucket_regional_domain_name
    override_host = aws_s3_bucket.index.bucket_regional_domain_name

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = aws_s3_bucket.index.bucket_regional_domain_name
  }

  default_ttl = local.index_default_ttl

  # TODO: uncomment to enable logging
  # logging_datadog {
  #   name  = "datadog"
  #   token = data.aws_ssm_parameter.datadog_api_key.value

  #   format = templatefile("index-crates-io/fastly-log-format.tftpl", {
  #     service_name = "index.crates.io"
  #     dd_app       = "crates-io-index",
  #     dd_env       = var.env,
  #   })
  # }

  # logging_s3 {
  #   name        = "s3-request-logs"
  #   bucket_name = aws_s3_bucket.logs.bucket

  #   s3_iam_role = aws_iam_role.fastly_assume_role.arn
  #   domain      = "s3.us-west-1.amazonaws.com"
  #   path        = "/fastly-requests/${var.index_domain_name}/"

  #   compression_codec = "zstd"
  # }
}

module "fastly_tls_subscription_index" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.index.id

  domains = [
    local.fastly_index_domain_name,
    var.index_domain_name
  ]
}

resource "aws_route53_record" "fastly_index_domain" {
  zone_id         = data.aws_route53_zone.index.id
  name            = local.fastly_index_domain_name
  type            = "CNAME"
  ttl             = 300
  allow_overwrite = true
  records         = module.fastly_tls_subscription_index.destinations
}

# TODO: uncomment when the other record is also weighted
# resource "aws_route53_record" "weighted_index_fastly" {
#   zone_id = data.aws_route53_zone.index.id
#   name    = var.index_domain_name
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_route53_record.fastly_index_domain.fqdn]

#   weighted_routing_policy {
#     weight = var.index_fastly_weight
#   }

#   set_identifier = "fastly"
# }
