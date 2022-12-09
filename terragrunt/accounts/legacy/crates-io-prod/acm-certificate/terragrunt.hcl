terraform {
  source = "git::../../../../..//terragrunt/modules/acm-certificate?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domains = [
    "crates.io",
    "static.crates.io",
    "index.crates.io",
  ]
}
