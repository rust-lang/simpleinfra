resource "aws_iam_openid_connect_provider" "gh_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  // Not actually used today, AWS has its own store of allowed certs
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}
