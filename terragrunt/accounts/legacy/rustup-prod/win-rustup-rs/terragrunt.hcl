terraform {
  source = "git::../../../../..//terragrunt/modules/win-rustup-rs?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domain_name = "win.rustup.rs"
  static_bucket = "static-rust-lang-org"
}
