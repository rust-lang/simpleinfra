locals {
  fastly_domain_name = "fastly-${var.static_domain_name}"
}

resource "fastly_service_vcl" "static" {
  name = var.static_domain_name

  domain {
    name = local.fastly_domain_name
  }

  domain {
    name = var.static_domain_name
  }

  backend {
    name = data.aws_s3_bucket.static.bucket

    address       = data.aws_s3_bucket.static.bucket_regional_domain_name
    override_host = data.aws_s3_bucket.static.bucket_regional_domain_name

    use_ssl           = true
    port              = 443
    ssl_cert_hostname = data.aws_s3_bucket.static.bucket_regional_domain_name
  }

  default_ttl = var.static_ttl

  # The VCL snippets can be tested here: https://fiddle.fastly.dev/fiddle/eb4b0dfb
  snippet {
    name    = "list files in S3"
    type    = "recv"
    content = <<-VCL
      if (req.url ~ "^\/dist\/\d{4}-\d{2}-\d{2}(\/|\/index.html)?$") {
        set req.url = "/list-files.html";
      }
    VCL
  }

  snippet {
    name    = "detect rustup.sh requests"
    type    = "recv"
    content = <<-VCL
      if (req.url ~ "^\/rustup\.sh$") {
        error 618 "redirect";
      }
    VCL
  }

  snippet {
    name    = "enable segmented caching"
    type    = "recv"
    content = "set req.enable_segmented_caching = true;"
  }

  snippet {
    name    = "set cache key for dist"
    type    = "fetch"
    content = <<-VCL
      if (req.url ~ "^\/dist/") {
        set beresp.http.Surrogate-Key = "/dist/*";
      }
    VCL
  }

  snippet {
    name    = "redirect rustup.sh to rustup.rs"
    type    = "error"
    content = <<-VCL
      if (obj.status == 618 && obj.response == "redirect") {
        set obj.status = 301;
        set obj.response = "Moved permanently";
        set obj.http.Location = "https://sh.rustup.rs";

        synthetic {"
      #!/bin/bash
      echo "The location of rustup.sh has moved."
      echo "Run the following command to install from the new location:"
      echo "    curl https://sh.rustup.rs -sSf | sh"
        "};

        return (deliver);
      }
    VCL
  }
}

module "fastly_tls_subscription" {
  source = "../fastly-tls-subscription"

  certificate_authority = "globalsign"
  aws_route53_zone_id   = data.aws_route53_zone.static.id

  domains = [
    local.fastly_domain_name,
    var.static_domain_name
  ]
}

resource "aws_route53_record" "fastly_static_domain" {
  zone_id         = data.aws_route53_zone.static.id
  name            = local.fastly_domain_name
  type            = "CNAME"
  ttl             = 300
  allow_overwrite = true
  records         = module.fastly_tls_subscription.destinations
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
