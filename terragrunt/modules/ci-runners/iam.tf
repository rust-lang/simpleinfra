// Grant CodeBuild project IAM role access to use the connection, as documented in
// https://docs.aws.amazon.com/codebuild/latest/userguide/connections-github-app.html#connections-github-role-access
data "aws_iam_policy_document" "codebuild_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-github-runner-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_policy_doc.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-github-runner-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection"
        ]
        Resource = [var.code_connection_arn]
      }
    ]
  })
}
