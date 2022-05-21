// Permissions for the people who can deploy to staging dev-desktop

resource "aws_iam_group" "infra_deploy_staging_dev_desktop" {
  name = "infra-deploy-staging-dev-desktop"
}

resource "aws_iam_group_policy_attachment" "infra_deploy_staging_dev_desktop_manage_own_credentials" {
  group      = aws_iam_group.infra_deploy_staging_dev_desktop.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "infra_deploy_staging_dev_desktop_enforce_mfa" {
  group      = aws_iam_group.infra_deploy_staging_dev_desktop.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy" "infra_deploy_staging_dev_desktop" {
  group = aws_iam_group.infra_deploy_staging_dev_desktop.name
  name  = "staging-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Parameters read by Ansible during deployment.
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:us-west-1:890664054962:parameter/staging/ansible/dev-desktop/*"
      },
    ]
  })
}
