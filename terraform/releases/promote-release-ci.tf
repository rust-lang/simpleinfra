// Resources used by the rust-lang/promote-release CI.

module "promote_release_ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "promote-release"
}

// IAM User used by CI to push the built images on ECR.

resource "aws_iam_role" "ci_promote_release" {
  name = "ci--rust-lang-promote-release"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = data.terraform_remote_state.shared.outputs.gha_oidc_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/promote-release:ref:refs/heads/master"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "promote_release_ci_pull" {
  role       = aws_iam_role.ci_promote_release.name
  policy_arn = module.promote_release_ecr.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "promote_release_ci_push" {
  role       = aws_iam_role.ci_promote_release.name
  policy_arn = module.promote_release_ecr.policy_push_arn
}
