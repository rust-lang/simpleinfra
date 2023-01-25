terraform {
  source = "git::../../../../..//terragrunt/modules/crates-io?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  webapp_domain_name = "crates.io"
  static_domain_name = "static.crates.io"
  index_domain_name  = "index.crates.io"
  dns_apex           = true

  static_bucket_name     = "crates-io"
  index_bucket_name      = "crates-io-index"

  static_ttl = 86400 // 1 day

  webapp_origin_domain = "crates-io.herokuapp.com"

  iam_prefix = "crates-io"

  strict_security_headers = true

  static_cloudfront_weight = 99
  static_fastly_weight = 1
}
