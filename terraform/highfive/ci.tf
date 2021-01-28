resource "aws_iam_policy" "update_service" {
  name        = "ecs-update-highfive"
  description = "Allow to redeploy and update highfive"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUpdate",
      "Effect": "Allow",
      "Action": "ecs:UpdateService",
      "Resource": "${module.ecs_service.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user" "ci" {
  name = "ci--rust-lang--highfive"
}

resource "aws_iam_user_policy_attachment" "ci_ecs" {
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.update_service.arn
}

resource "aws_iam_user_policy_attachment" "ci_ecr_push" {
  user       = aws_iam_user.ci.name
  policy_arn = module.ecr.policy_push_arn
}

resource "aws_iam_user_policy_attachment" "ci_ecr_pull" {
  user       = aws_iam_user.ci.name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}
