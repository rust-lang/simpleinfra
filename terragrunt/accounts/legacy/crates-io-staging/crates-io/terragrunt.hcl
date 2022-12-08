terraform {
  source = "../../../../modules//crates-io"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "certificate" {
  config_path = "../acm-certificate"
}

inputs = {
  webapp_domain_name = "staging.crates.io"
  static_domain_name = "static.staging.crates.io"
  index_domain_name  = "index.staging.crates.io"

  static_bucket_name     = "staging-crates-io"
  index_bucket_name      = "staging-crates-io-index"

  webapp_origin_domain = "staging-crates-io.herokuapp.com"

  iam_prefix = "staging-crates-io"

  strict_security_headers = true

  certificate_arn = dependency.certificate.outputs.arn
}
