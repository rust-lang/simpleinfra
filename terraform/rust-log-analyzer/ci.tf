// Resources used by the rust-lang/rust-log-analyzer CI.

// ECR repository used to store the Docker images built by CI. The images are
// then deployed to ECS.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "rust-log-analyzer"
}

// IAM User used rust-lang/sync-team's CI to push the built images on ECR.

module "iam_ci" {
  source = "../shared/modules/gha-iam-user"
  org    = "rust-lang"
  repo   = "rust-log-analyzer"
}

resource "aws_iam_user_policy_attachment" "ci_pull" {
  user       = module.iam_ci.user_name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = module.iam_ci.user_name
  policy_arn = module.ecr.policy_push_arn
}
