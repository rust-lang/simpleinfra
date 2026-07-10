terraform {
  source = "../../../..//terragrunt/modules/docs-rs-event-queue"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
