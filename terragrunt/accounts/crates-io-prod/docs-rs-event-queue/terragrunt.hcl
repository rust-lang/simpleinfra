terraform {
  source = "../../../..//terragrunt/modules/docs-rs-event-queue"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  # Role attached to the legacy EC2 instance currently running docs.rs.
  consumer_principal_arns = ["arn:aws:iam::890664054962:role/docs-rs"]
}
