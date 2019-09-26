// This file contains the configuration for Crater.

resource "aws_iam_user" "crater_ci" {
  name = "ci--rust-lang--crater"
}

resource "aws_iam_access_key" "crater_ci" {
  user = "${aws_iam_user.crater_ci.name}"
}

resource "aws_iam_user_policy_attachment" "crater_ci_push" {
  user       = "${aws_iam_user.crater_ci.name}"
  policy_arn = "${module.ecr_crater.policy_push_arn}"
}

resource "aws_iam_user_policy_attachment" "crater_ci_pull" {
  user       = "${aws_iam_user.crater_ci.name}"
  policy_arn = "${module.ecr_crater.policy_pull_arn}"
}
