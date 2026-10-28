terraform {
  source = "../../../modules//datadog-aws"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env            = "prod"
  s3_log_buckets = []

  datadog_archives = {
    bucket = "static-rust-lang-org-datadog-archives"
    services = {
      "static.rust-lang.org" = "static.rust-lang.org"
    }
  }
}
