// This file contains the configuration for Crater agents.

resource "aws_iam_user" "agent_outside_aws" {
  name = "crater-agent--outside-aws"
}

resource "aws_iam_access_key" "agent_outside_aws" {
  user = "${aws_iam_user.agent_outside_aws.name}"
}

resource "aws_iam_role" "agent" {
  name = "crater-agent"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeRoleEC2",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    },
    {
      "Sid": "AssumeRoleCraterAgentOutsideAWS",
      "Principal": {
        "AWS": "${aws_iam_user.agent_outside_aws.arn}"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "agent_pull_ecr" {
  role       = "${aws_iam_role.agent.name}"
  policy_arn = "${var.ecr_repo.policy_pull_arn}"
}
