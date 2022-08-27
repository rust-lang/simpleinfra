// Resources needed for the CI of rust-lang/team and rust-lang/sync-team.

// ECR repo used to store the Docker image built by rust-lang/sync-team's CI.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "sync-team"
}

// IAM role used by rust-lang/sync-team's CI to push the built images on ECR.

module "ci_sync_team" {
  source = "../shared/modules/gha-oidc-role"
  org    = "rust-lang"
  repo   = "sync-team"
  branch = "master"
}

resource "aws_iam_role_policy_attachment" "ci_sync_team_pull" {
  role       = module.ci_sync_team.role.id
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "ci_sync_team_push" {
  role       = module.ci_sync_team.role.id
  policy_arn = module.ecr.policy_push_arn
}

// IAM role and Lambda function used by rust-lang/team CI to start the sync.
//
// The CI needs to call the intermediate Lambda function to start the CodeBuild
// for security reasons, as CodeBuild's StartBuild API call allows to override
// pretty much any build parameter, including the executed commands. That could
// allow an attacker to (for example) leak secrets.

module "ci_team" {
  source = "../shared/modules/gha-oidc-role"
  org    = "rust-lang"
  repo   = "team"
  branch = "master"
}

resource "aws_iam_role_policy" "ci_sync_team_lambda" {
  name = "start-sync-team"
  role = module.ci_team.role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InvokeLambda"
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = module.lambda_start_sync_team.arn
      }
    ]
  })
}

module "lambda_start_sync_team" {
  source = "../shared/modules/lambda"

  name       = "start-sync-team"
  source_dir = "lambdas/start-sync-team"
  handler    = "index.handler"
  runtime    = "nodejs16.x"
  role_arn   = aws_iam_role.start_execution.arn
}
