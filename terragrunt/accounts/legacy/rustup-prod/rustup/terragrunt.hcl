terraform {
  source = "git::../../../../..//terragrunt/modules/rustup?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
