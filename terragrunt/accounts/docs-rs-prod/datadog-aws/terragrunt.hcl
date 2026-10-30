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
    bucket = "docs-rs-datadog-archives"
    services = {
      "docs.rs-nginx" = "\"docs.rs nginx\""
    }
  }
}
