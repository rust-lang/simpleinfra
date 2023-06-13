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

  static_cloudfront_weight = 99
  static_fastly_weight = 1
}
