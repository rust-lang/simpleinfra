terraform {
  source = "../../../../modules//release-distribution"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  environment = "prod"

  static_domain_name = "static.rust-lang.org"
  doc_domain_name = "doc.rust-lang.org"

  static_bucket = ""
  log_bucket = ""
}
