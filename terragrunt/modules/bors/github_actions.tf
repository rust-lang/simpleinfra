resource "aws_iam_openid_connect_provider" "gh_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  // Not actually used today, AWS has its own store of allowed certs
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "gha" {
  name = "gha-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.gh_oidc.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "${var.trusted_sub}"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "allow-ecr-push"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "GetAuthorizationToken"
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecs:UpdateService",
            # Used to wait until the service is stable
            "ecs:DescribeServices"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
