terraform {
  source = "../../../..//terragrunt/modules/ci-runners"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  code_connection_name = "prod-gh-connection"
  repository           = "rust-lang-ci/rust"
}
