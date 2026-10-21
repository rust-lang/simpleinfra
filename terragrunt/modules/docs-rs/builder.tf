module "builder_ecr" {
  source = "../ecr-repo"
  name   = "docs-rs-build-server"
}

resource "aws_launch_template" "builder" {
  name_prefix   = "docs-rs-builder-"
  image_id      = data.aws_ami.ubuntu24.id
  instance_type = var.builder_config.instance_type
  user_data     = sensitive(base64gzip(local.builder_user_data))

  iam_instance_profile {
    name = aws_iam_instance_profile.builder.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.builder.id]
    delete_on_termination       = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
    http_endpoint               = "enabled"
  }

  block_device_mappings {
    device_name = data.aws_ami.ubuntu24.root_device_name
    ebs {
      volume_size           = var.builder_config.volume_size
      volume_type           = "gp3"
      iops                  = var.builder_config.volume_iops
      throughput            = var.builder_config.volume_throughput
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "docs-rs-builder" }
  }

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = length(base64gzip(local.builder_user_data)) / 4 * 3 - length(regex("=*$", base64gzip(local.builder_user_data))) <= 16384
      error_message = "Builder cloud-init exceeds EC2's 16 KiB user data limit."
    }
  }
}

resource "aws_autoscaling_group" "builder" {
  name                      = local.builder_asg_name
  min_size                  = var.builder_count
  max_size                  = var.builder_count
  desired_capacity          = var.builder_count
  vpc_zone_identifier       = [var.cluster_config.subnet_ids[0]]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_instance_warmup   = 120
  # Bootstrap may wait for the first image to be published. Readiness is gated
  # by the launch hook; terraform apply does not wait for the initial fleet.
  wait_for_capacity_timeout = "0"

  launch_template {
    id      = aws_launch_template.builder.id
    version = tostring(aws_launch_template.builder.latest_version)
  }

  initial_lifecycle_hook {
    name                 = local.builder_launch_hook
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    heartbeat_timeout    = 1800
    default_result       = "ABANDON"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      max_healthy_percentage = 100
      instance_warmup        = 120
      skip_matching          = true
    }
  }

  tag {
    key                 = "Name"
    value               = "docs-rs-builder"
    propagate_at_launch = true
  }

  depends_on = [
    aws_iam_role_policy.builder_startup,
    aws_iam_role_policy.builder_s3,
    aws_iam_role_policy_attachment.builder_ecr_pull,
  ]
}

data "aws_ami" "ubuntu24" {
  most_recent = true
  owners      = ["099720109477"] // Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// The trusted builder uses the instance profile for SSM, ECR, logs, and S3.

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
          "s3:GetObject",
          "s3:ListBucket",
          "s3:AbortMultipartUpload",
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

// Builders initiate outbound connections and accept no inbound traffic.
resource "aws_security_group" "builder" {
  vpc_id      = var.cluster_config.vpc_id
  name        = "docs-rs-builder"
  description = "Access rules for the docs-rs builder."

  ingress = []

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

data "aws_partition" "builder" {}

data "aws_region" "builder" {}
