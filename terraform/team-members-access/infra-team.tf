// Permissions for the members of the infra team as a whole.

resource "aws_iam_group" "infra_team" {
  name = "infra-team"
}

resource "aws_iam_group_policy_attachment" "infra_team_manage_own_credentials" {
  group      = aws_iam_group.infra_team.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "infra_team_enforce_mfa" {
  group      = aws_iam_group.infra_team.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

// Infra team members are allowed to have read access to IAM
resource "aws_iam_group_policy_attachment" "infra_team_iam_access" {
  group      = aws_iam_group.infra_team.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

// Infra team members are allowed to have read access to Route53
resource "aws_iam_group_policy_attachment" "infra_team_route53_access" {
  group      = aws_iam_group.infra_team.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess"
}
