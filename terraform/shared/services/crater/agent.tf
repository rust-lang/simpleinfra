// This file contains the configuration for Crater agents.

resource "aws_iam_user" "agent_outside_aws" {
  name = "crater-agent--outside-aws"
}

resource "aws_iam_access_key" "agent_outside_aws" {
  user = aws_iam_user.agent_outside_aws.name
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
  role       = aws_iam_role.agent.name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_instance_profile" "agent" {
  name = "crater-agent"
  role = aws_iam_role.agent.name
}

resource "aws_network_interface" "agent" {
  subnet_id = var.agent_subnet_id
  security_groups = [
    var.common_security_group_id,
  ]
}

resource "aws_instance" "agent" {
  ami                     = var.agent_ami_id
  instance_type           = "c5.2xlarge"
  key_name                = var.agent_key_pair
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false
  iam_instance_profile    = aws_iam_instance_profile.agent.name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 2000
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.agent.id
    device_index         = 0
  }

  tags = {
    Name = "crater-aws-1"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}
