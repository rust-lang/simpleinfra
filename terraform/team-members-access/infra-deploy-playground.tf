// Permissions for the members of the infra team who can deploy the playground.

resource "aws_iam_group" "infra_deploy_playground" {
  name = "infra-deploy-playground"
}

resource "aws_iam_group_policy_attachment" "infra_deploy_playground_manage_own_credentials" {
  group      = aws_iam_group.infra_deploy_playground.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "infra_deploy_playground_enforce_mfa" {
  group      = aws_iam_group.infra_deploy_playground.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy" "infra_deploy_playground" {
  group = aws_iam_group.infra_deploy_playground.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Parameters read by Ansible during deployment.
      {
        Effect = "Allow"
        Action = ["ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = [
          "arn:aws:ssm:us-west-1:890664054962:parameter/prod/ansible/all/*",
          "arn:aws:ssm:us-west-1:890664054962:parameter/prod/ansible/playground/*",
          "arn:aws:ssm:us-west-1:890664054962:parameter/staging/ansible/all/*",
        ]
      },
    ]
  })
}
