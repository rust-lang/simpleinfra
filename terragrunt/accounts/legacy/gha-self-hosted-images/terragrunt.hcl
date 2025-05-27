terraform {
  source = "../../../..//terragrunt/modules/gha-self-hosted-images"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
