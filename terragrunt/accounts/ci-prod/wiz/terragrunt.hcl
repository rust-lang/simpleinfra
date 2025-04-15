terraform {
  source = "../../../..//terragrunt/modules/wiz"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
