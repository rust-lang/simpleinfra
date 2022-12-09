terraform {
  source = "../../../../modules//acm-certificate"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domains = [
    "staging.crates.io",
    "static.staging.crates.io",
    "index.staging.crates.io",
  ]
}
