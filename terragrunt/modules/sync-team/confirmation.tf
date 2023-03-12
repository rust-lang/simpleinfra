data "aws_ssm_parameter" "confirmation_parameters" {
  for_each = toset([
    "/prod/sync-team-confirmation/github-oauth-client-id",
    "/prod/sync-team-confirmation/github-oauth-client-secret",
  ])

  name = each.value
  // We don't need the actual value, just their ARNs:
  with_decryption = false
}

module "lambda_confirmation" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "sync-team-confirmation"
  description   = "Out-of-band confirmation before applying sync-team changes."
  handler       = "index.handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "lambdas/sync-team-confirmation"

  create_lambda_function_url = true

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.sync_team.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"],
        Resource = [for p in data.aws_ssm_parameter.confirmation_parameters : p.arn]
      }
    ]
  })
}
