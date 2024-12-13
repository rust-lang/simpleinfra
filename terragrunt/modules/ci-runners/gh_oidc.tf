// Docs: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
resource "aws_iam_openid_connect_provider" "github_actions_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  // unused
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}
