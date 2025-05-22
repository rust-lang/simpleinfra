terraform {
  source = "../../../..//terragrunt/modules/grafana"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  workspace_name = "metrics-initiative-prod"
}