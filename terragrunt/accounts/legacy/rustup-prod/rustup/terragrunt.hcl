terraform {
  source = "../../../../..//terragrunt/modules/rustup"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  builds_domain_name = "rustup-builds.rust-lang.org"
}
