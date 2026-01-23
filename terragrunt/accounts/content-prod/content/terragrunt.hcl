terraform {
  source = "../../../..//terragrunt/modules/content"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
