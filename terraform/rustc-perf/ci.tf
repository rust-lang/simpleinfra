resource "aws_iam_policy" "update_service" {
  name        = "ecs-update-rustc-perf"
  description = "Allow to redeploy and update rustc-perf"

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
  name = "ci--rust-lang--rustc-perf"
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

resource "aws_ssm_parameter" "ci_access_key" {
  name  = "/iam-users/${aws_iam_access_key.ci.user}/access-keys/${aws_iam_access_key.ci.id}"
  value = aws_iam_access_key.ci.secret

  type = "SecureString"
}
