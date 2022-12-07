terraform {
  source = "../../../modules//resource-group"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  resource_group_name = "dev-desktops-prod"
  location = "West US 2"
}
