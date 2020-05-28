// Definition of the resources the CI of rust-lang/discord-mods-bot needs.

// ECR repository used to store the containers built by CI.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "crates-io-ops-bot"
}

// IAM User used by CI to push images to the repository created above. The user
// has permissions to pull and push to the repository created earlier, and to
// redeploy the ECS service of the bot.
//
// The IAM Access Key is stored in AWS SSM Parameter Store under the key:
//
//    /iam-users/ci--rust-lang--discord-mods-bot/access-keys/ACCESS_KEY_ID
//

resource "aws_iam_user" "ci" {
  name = "ci--rust-lang--crates-io-ops-bot"
}

resource "aws_iam_user_policy" "update_service" {
  name = "update-ecs-service"
  user = aws_iam_user.ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowUpdate"
        Effect   = "Allow"
        Action   = "ecs:UpdateService"
        Resource = aws_ecs_service.service.id
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = aws_iam_user.ci.name
  policy_arn = module.ecr.policy_push_arn
}

resource "aws_iam_user_policy_attachment" "ci_pull" {
  user       = aws_iam_user.ci.name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

resource "aws_ssm_parameter" "ci_access_key" {
  name  = "/iam-users/ci--rust-lang--crates-io-ops-bot/access-keys/${aws_iam_access_key.ci.id}"
  value = aws_iam_access_key.ci.secret

  type = "SecureString"
}
