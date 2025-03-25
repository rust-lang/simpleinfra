// Resources needed for the CI of rust-lang/team and rust-lang/sync-team.

// ECR repo used to store the Docker image built by rust-lang/sync-team's CI.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "sync-team"
}

// IAM role used by rust-lang/sync-team's CI to push the built images to ECR
// and to invoke the lambda function that runs sync-team.

module "ci_sync_team" {
  source      = "../shared/modules/gha-oidc-role"
  org         = "rust-lang"
  repo        = "sync-team"
  environment = "deploy"
}

// IAM role used by rust-lang/team's CI to invoke the lambda function that
// runs sync-team.

module "ci_team" {
  source      = "../shared/modules/gha-oidc-role"
  org         = "rust-lang"
  repo        = "team"
  environment = "deploy"
}

// Policies that allow the sync-team role to interact with ECR

resource "aws_iam_role_policy_attachment" "ci_sync_team_pull" {
  role       = module.ci_sync_team.role.id
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "ci_sync_team_push" {
  role       = module.ci_sync_team.role.id
  policy_arn = module.ecr.policy_push_arn
}

// Policy for interacting with the lambda function that runs sync-team through CodeBuild.
//
// The CI needs to call the intermediate Lambda function to start the CodeBuild
// for security reasons, as CodeBuild's StartBuild API call allows to override
// pretty much any build parameter, including the executed commands. That could
// allow an attacker to (for example) leak secrets.

resource "aws_iam_policy" "start_sync_team_policy" {
  name = "start-sync-team-policy"
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

// Attaching the invoke lambda function policy to the team and team-sync repos' roles.

resource "aws_iam_role_policy_attachment" "start_sync_team_team_repo" {
  role       = module.ci_team.role.id
  policy_arn = aws_iam_policy.start_sync_team_policy.arn
}

resource "aws_iam_role_policy_attachment" "start_sync_team_sync_team_repo" {
  role       = module.ci_sync_team.role.id
  policy_arn = aws_iam_policy.start_sync_team_policy.arn
}

// The lambda function for running team-sync

module "lambda_start_sync_team" {
  source = "../shared/modules/lambda"

  name       = "start-sync-team"
  source_dir = "lambdas/start-sync-team"
  handler    = "index.handler"
  runtime    = "nodejs20.x"
  role_arn   = aws_iam_role.start_execution.arn
}
