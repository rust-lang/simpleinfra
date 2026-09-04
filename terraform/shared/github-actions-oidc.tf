// This section configures the trust relationship between GitHub Actions and
// our AWS account.

locals {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = local.url

  client_id_list = ["sts.amazonaws.com"]
}
