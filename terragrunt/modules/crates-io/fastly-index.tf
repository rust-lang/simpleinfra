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

  logging_s3 {
    name        = "s3-request-logs"
    bucket_name = aws_s3_bucket.logs.bucket

    s3_iam_role = aws_iam_role.fastly_assume_role.arn
    domain      = "s3.us-west-1.amazonaws.com"
    path        = "/fastly-requests/${var.index_domain_name}/"

    compression_codec = "zstd"
  }

  # See https://www.fastly.com/documentation/guides/integrations/non-fastly-services/amazon-s3/#using-an-amazon-s3-private-bucket
  snippet {
    name    = "S3 Private Access"
    type    = "miss"
    content = <<EOT
      declare local var.awsAccessKey STRING;
      declare local var.awsSecretKey STRING;
      declare local var.awsS3Bucket STRING;
      declare local var.awsRegion STRING;
      declare local var.awsS3Host STRING;
      declare local var.canonicalHeaders STRING;
      declare local var.signedHeaders STRING;
      declare local var.canonicalRequest STRING;
      declare local var.canonicalQuery STRING;
      declare local var.stringToSign STRING;
      declare local var.dateStamp STRING;
      declare local var.signature STRING;
      declare local var.scope STRING;

      set var.awsAccessKey = "${aws_iam_access_key.fastly_s3_index_reader.id}";
      set var.awsSecretKey = "${aws_iam_access_key.fastly_s3_index_reader.secret}";
      set var.awsS3Bucket = "${aws_s3_bucket.index.bucket}";
      set var.awsRegion = "${aws_s3_bucket.index.region}";
      set var.awsS3Host = var.awsS3Bucket ".s3." var.awsRegion ".amazonaws.com";

      if (req.method == "GET" && !req.backend.is_shield) {

        set bereq.http.x-amz-content-sha256 = digest.hash_sha256("");
        set bereq.http.x-amz-date = strftime({"%Y%m%dT%H%M%SZ"}, now);
        set bereq.http.host = var.awsS3Host;
        set bereq.url = querystring.remove(bereq.url);
        set bereq.url = regsuball(urlencode(urldecode(bereq.url.path)), {"%2F"}, "/");
        set var.dateStamp = strftime({"%Y%m%d"}, now);
        set var.canonicalHeaders = ""
          "host:" bereq.http.host LF
          "x-amz-content-sha256:" bereq.http.x-amz-content-sha256 LF
          "x-amz-date:" bereq.http.x-amz-date LF
        ;
        set var.canonicalQuery = "";
        set var.signedHeaders = "host;x-amz-content-sha256;x-amz-date";
        set var.canonicalRequest = ""
          "GET" LF
          bereq.url.path LF
          var.canonicalQuery LF
          var.canonicalHeaders LF
          var.signedHeaders LF
          digest.hash_sha256("")
        ;

        set var.scope = var.dateStamp "/" var.awsRegion "/s3/aws4_request";

        set var.stringToSign = ""
          "AWS4-HMAC-SHA256" LF
          bereq.http.x-amz-date LF
          var.scope LF
          regsub(digest.hash_sha256(var.canonicalRequest),"^0x", "")
        ;

        set var.signature = digest.awsv4_hmac(
          var.awsSecretKey,
          var.dateStamp,
          var.awsRegion,
          "s3",
          var.stringToSign
        );

        set bereq.http.Authorization = "AWS4-HMAC-SHA256 "
          "Credential=" var.awsAccessKey "/" var.scope ", "
          "SignedHeaders=" var.signedHeaders ", "
          "Signature=" + regsub(var.signature,"^0x", "")
        ;
        unset bereq.http.Accept;
        unset bereq.http.Accept-Language;
        unset bereq.http.User-Agent;
        unset bereq.http.Fastly-Client-IP;
      }
    EOT
  }

  snippet {
    name    = "rewrite root to index"
    type    = "recv"
    content = <<-VCL
      if (req.url == "/") {
        set req.url = "/index.html";
      }
    VCL
  }

  snippet {
    name    = "enable segmented caching"
    type    = "recv"
    content = <<-VCL
      set req.enable_segmented_caching = true;
      set segmented_caching.block_size = 10000000;
    VCL
  }
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

resource "aws_route53_record" "weighted_index_fastly" {
  zone_id = data.aws_route53_zone.index.id
  name    = var.index_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_record.fastly_index_domain.fqdn]

  weighted_routing_policy {
    weight = var.index_fastly_weight
  }

  set_identifier = "fastly"
}
