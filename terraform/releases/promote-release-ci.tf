// Resources used by the rust-lang/promote-release CI.

module "promote_release_ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "promote-release"
}

// IAM User used by CI to push the built images on ECR.

module "promote_release_iam_ci" {
  source = "../shared/modules/gha-iam-user"
  org    = "rust-lang"
  repo   = "promote-release"
}


resource "aws_iam_user_policy_attachment" "promote_release_ci_pull" {
  user       = module.promote_release_iam_ci.user_name
  policy_arn = module.promote_release_ecr.policy_pull_arn
}

resource "aws_iam_user_policy_attachment" "promote_release_ci_push" {
  user       = module.promote_release_iam_ci.user_name
  policy_arn = module.promote_release_ecr.policy_push_arn
}
