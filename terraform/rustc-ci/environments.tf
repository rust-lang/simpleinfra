module "security" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  iam_prefix  = "ci--rust-lang-ci--rsec"
  repo        = "rust-lang-ci/rsec"
  source_repo = "rust-lang-ci/rsec"

  caches_bucket    = "rust-lang-security-ci-caches"
  artifacts_bucket = "rust-lang-security-ci-artifacts"

  delete_caches_after_days    = 30
  delete_artifacts_after_days = 90
  response_policy_id          = data.terraform_remote_state.shared.outputs.mdbook_response_policy
}
