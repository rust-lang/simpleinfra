# One-off migration from Terragrunt, which ran the module as the root module.
# These blocks move the existing state into `module.wiz`. Delete this file
# once the configuration has been applied.

moved {
  from = aws_iam_policy.inventory
  to   = module.wiz.aws_iam_policy.inventory
}

moved {
  from = aws_iam_policy.inventory_additional
  to   = module.wiz.aws_iam_policy.inventory_additional
}

moved {
  from = aws_iam_role_policy_attachment.inventory
  to   = module.wiz.aws_iam_role_policy_attachment.inventory
}

moved {
  from = aws_iam_role_policy_attachment.inventory_additional
  to   = module.wiz.aws_iam_role_policy_attachment.inventory_additional
}

moved {
  from = aws_iam_role_policy.tf-policy
  to   = module.wiz.aws_iam_role_policy.tf-policy
}

moved {
  from = aws_iam_role.user-role-tf
  to   = module.wiz.aws_iam_role.user-role-tf
}

moved {
  from = aws_iam_role_policy_attachment.view_only_access_role_policy_attach
  to   = module.wiz.aws_iam_role_policy_attachment.view_only_access_role_policy_attach
}

moved {
  from = aws_iam_role_policy_attachment.security_audit_role_policy_attach
  to   = module.wiz.aws_iam_role_policy_attachment.security_audit_role_policy_attach
}
