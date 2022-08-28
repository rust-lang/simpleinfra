// Configure all static websites hosted in our AWS account.

module "static_website_ci_mirrors" {
  source = "./modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = "ci-mirrors.rust-lang.org"
  origin_domain_name = aws_s3_bucket.rust_lang_ci_mirrors.bucket_regional_domain_name
  response_policy_id = aws_cloudfront_response_headers_policy.s3.id
}

module "static_website_crates_io_index_temp" {
  source = "./modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = "crates-io-index-temp.rust-lang.org"
  origin_domain_name = aws_s3_bucket.rust_lang_crates_io_index.bucket_regional_domain_name
  response_policy_id = aws_cloudfront_response_headers_policy.s3.id
}

resource "aws_cloudfront_response_headers_policy" "s3" {
  name    = "S3StaticFiles"
  comment = "Policy for s3 files"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000
      override                   = true
    }
  }
}
