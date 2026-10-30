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
      "crates.io"              = "crates.io"
      "static.crates.io"       = "static.crates.io"
      "crates-io-fastly-index" = "crates-io-fastly-index"
    }
  }
}
