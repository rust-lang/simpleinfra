terraform {
  source = "../../../../..//terragrunt/modules/release-distribution"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  environment = "dev"

  static_domain_name = "dev-static.rust-lang.org"
  doc_domain_name = "dev-doc.rust-lang.org"

  static_bucket = "dev-static-rust-lang-org"
  log_bucket = "rust-release-logs"

  static_ttl = 86400 // 1 day
}
