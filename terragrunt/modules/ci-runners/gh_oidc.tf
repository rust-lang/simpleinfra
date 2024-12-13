// Docs: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
resource "aws_iam_openid_connect_provider" "github_actions_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  // unused
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "github_actions_ci_role" {
  name = "ci--rust-lang--aws-runners-test"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRoleWithWebIdentity",
        ]
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions_provider.arn
        }
        Condition = {
          // StringLike is used with a wildcard operator (*) to allow any branch, pull request merge branch
          // of the repository to assume a role in AWS
          StringLike : {
            "token.actions.githubusercontent.com:sub" : "repo:rust-lang/aws-runners-test:ref:*"
          },
          StringEquals : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
