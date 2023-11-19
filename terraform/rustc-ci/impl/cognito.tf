resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.iam_prefix}--rustc-ci"
  allow_classic_flow               = true
  allow_unauthenticated_identities = false
  openid_connect_provider_arns     = ["${data.aws_iam_openid_connect_provider.gha.arn}"]
}

resource "aws_cognito_identity_pool_provider_principal_tag" "gha_mapper" {
  identity_pool_id       = aws_cognito_identity_pool.main.id
  identity_provider_name = data.aws_iam_openid_connect_provider.gha.arn
  use_defaults           = false

  // This maps the claims on the left (from GHA, see https://token.actions.githubusercontent.com/.well-known/openid-configuration)
  // to "RequestTag"'s on the right. These are then matchable in the AssumeRole policy.
  principal_tags = {
    actor        = "actor"
    workflow_sha = "sha"
    run_id       = "run_id"
    event        = "event_name"
    ref          = "ref"
    repository   = "repository"
  }
}
