# Give the existing organization-wide Wiz scanner read-only/security-audit
# access, matching the baseline used by the other production AWS accounts.
terraform {
  source = "../../../..//terragrunt/modules/wiz"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}
