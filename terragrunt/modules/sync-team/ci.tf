// Resources needed for the CI of rust-lang/team and rust-lang/sync-team.

// ECR repo used to store the Docker image built by rust-lang/sync-team's CI.

module "ecr" {
  source = "../ecr-repo"
  name   = "sync-team"
}

// IAM role used by rust-lang/sync-team's CI to push the built images to ECR
// and to invoke the lambda function that runs sync-team.

module "ci_sync_team" {
  source = "../gha-oidc-role"
  org    = "rust-lang"
  repo   = "sync-team"
  branch = "master"
}

// IAM role used by rust-lang/team's CI to invoke the lambda function that
// runs sync-team.

module "ci_team" {
  source = "../gha-oidc-role"
  org    = "rust-lang"
  repo   = "team"
  branch = "master"
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
        Resource = module.lambda_start_sync_team.lambda_function_arn
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
  role = module.ci_sync_team.role.id

  policy_arn = aws_iam_policy.start_sync_team_policy.arn
}

// The lambda function for running team-sync

module "lambda_start_sync_team" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "start-sync-team"
  description   = "Start sync-team from CI"
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  publish       = true

  source_path = "lambdas/start-sync-team"

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.sync_team.arn
      }
    ]
  })
}
