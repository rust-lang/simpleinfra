// This file defines the users and permissions related to the Infrastructure
// Team members with admin access.

locals {
  infra_admins = [
    "acrichto",
    "pietroalbini",
    "simulacrum",
  ]
}

resource "aws_iam_user" "infra_admins" {
  for_each = toset(local.infra_admins)
  name     = each.value
}

resource "aws_iam_group" "infra_admins" {
  name = "infra-admins"
}

resource "aws_iam_user_group_membership" "infra_admins" {
  for_each = toset(local.infra_admins)
  user     = each.value
  groups   = [aws_iam_group.infra_admins.name]
}

resource "aws_iam_group_policy_attachment" "infra_admins_manage_own_credentials" {
  group      = aws_iam_group.infra_admins.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "infra_admins_enforce_mfa" {
  group      = aws_iam_group.infra_admins.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy" "infra_admins" {
  group = aws_iam_group.infra_admins.name
  name  = "full-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
    ]
  })
}
