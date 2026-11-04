terraform {
  source = "../../../modules//datadog-aws"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "prod"

  datadog_archives = {
    bucket = "crates-io-datadog-archives"
    services = {
    "crates.io"              = { service = "crates-io" }
    "static.crates.io"       = { service = "static.crates.io" }
    "crates-io-fastly-index" = { service = "crates-io-fastly-index", env = "production" }
    }
  }
}
