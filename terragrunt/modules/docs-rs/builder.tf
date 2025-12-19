// The autoscaling group for the builder

resource "aws_autoscaling_group" "builder" {
  name                = "docs-rs-builder"
  vpc_zone_identifier = var.cluster_config.subnet_ids
  max_size            = var.max_num_builder_instances
  min_size            = var.min_num_builder_instances
  # Let the instances get warm
  default_instance_warmup = 60

  launch_template {
    id      = aws_launch_template.builder.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "builder" {
  name_prefix   = "builder"
  image_id      = data.aws_ami.builder.id
  instance_type = "t2.large"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.builder.id]
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.builder.arn
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 64
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "docs-rs-builder"
    }
  }
}

data "aws_ami" "builder" {
  most_recent = true
  name_regex  = "^docs-rs-builder-*"
  owners      = ["self"]
}

// The instance profile the builder will assume when communicating with s3

resource "aws_iam_instance_profile" "builder" {
  name = "builder"
  role = aws_iam_role.builder.name
}

resource "aws_iam_role" "builder" {
  name = "builder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "builder_s3" {
  role = aws_iam_role.builder.name
  name = "builder_s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Access to s3
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:PutObjectTagging",
          "s3:DeleteObject"
        ]

        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })
}

// Security group allowing all egress and ssh ingress from the bastion instance
resource "aws_security_group" "builder" {
  vpc_id      = var.cluster_config.vpc_id
  name        = "docs-rs-builder"
  description = "Access rules for the docs-rs builder."

  // SSH access from the bastion instance
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    description     = "SSH access from bastion"
    security_groups = [aws_security_group.web.id]
  }

  // Allow outgoing connections

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all IPv4 egress traffic."
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all IPv6 egress traffic."
  }

  tags = {
    Name = "docs-rs-builder"
  }
}
