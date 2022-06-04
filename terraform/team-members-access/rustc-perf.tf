// This file defines the permissions of rustc-perf team members with access to the
// production environment.

resource "aws_iam_group" "rustc_perf" {
  name = "rustc-perf"
}

resource "aws_iam_group_policy_attachment" "rustc_perf_manage_own_credentials" {
  group      = aws_iam_group.rustc_perf.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "rustc_perf_enforce_mfa" {
  group      = aws_iam_group.rustc_perf.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_ssm_parameter" "rustc_perf_credentials" {
  name            = "/prod/rds/shared/connection-urls/rustc_perf"
  with_decryption = false
}

resource "aws_iam_group_policy" "rustc_perf" {
  group = aws_iam_group.rustc_perf.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRDSCredentialsAccess"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = data.aws_ssm_parameter.rustc_perf_credentials.arn
      }
    ]
  })
}
