terraform {
  source = "git::../../../../..//terragrunt/modules/release-distribution?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  environment = "prod"

  static_domain_name = "static.rust-lang.org"
  doc_domain_name = "doc.rust-lang.org"

  static_bucket = "static-rust-lang-org"
  log_bucket = "rust-release-logs"

  static_ttl = 86400 // 1 day

  # minimum weight AWS allows.
  static_cloudfront_weight = 0
  # maximum weight AWS allows
  static_fastly_weight = 255
  # Percentage of traffic going through Fastly: 255/(255+1)*100 = 99.6%
}
