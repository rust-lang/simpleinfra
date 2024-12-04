// Grant CodeBuild project IAM role access to use the connection, as documented in
// https://docs.aws.amazon.com/codebuild/latest/userguide/connections-github-app.html#connections-github-role-access
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-github-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Add inline or managed policy for the permissions
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
        Resource = [
          var.code_connection_arn
        ]
      }
    ]
  })
}
