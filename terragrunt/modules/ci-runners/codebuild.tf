# Codebuild has a separate webhook target per runner type,
# and it has to receive webhooks about all jobs starting.
# So adding projects results in more webhooks sent from GitHub to AWS.

# AWS has a webhook rate limit on the number of build requests that can be made per second, and in the auto build we start many builds in parallel.

# Check out https://github.com/rust-lang/rust/settings/hooks if jobs don't start. It might be that
# you are being rate limited by AWS.

module "ubuntu_22_36c" {
  source = "../../modules/codebuild-project"

  name                = "ubuntu-22-36c"
  service_role        = aws_iam_role.codebuild_role.arn
  compute_type        = "BUILD_GENERAL1_XLARGE"
  repository          = var.repository
  code_connection_arn = aws_codeconnections_connection.github_connection.arn
}
