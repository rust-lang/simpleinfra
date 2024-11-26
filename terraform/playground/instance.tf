resource "aws_eip" "playground2" {
  domain = "vpc"
  tags = {
    Name = "playground2"
  }
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

data "dns_a_record_set" "bastion" {
  host = "bastion.infra.rust-lang.org"
}

resource "aws_security_group" "playground" {
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name        = "rust-prod-playground"
  description = "Access rules for the production playground instance."

  // SSH access from the bastion (on the public interface)

  dynamic "ingress" {
    for_each = toset(data.dns_a_record_set.bastion.addrs)
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
      description = "SSH from the bastion"
    }
  }

  dynamic "ingress" {
    for_each = toset(data.dns_a_record_set.bastion.addrs)
    content {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["${ingress.value}/32"]
      description = "ICMP from the bastion"
    }
  }

  // node_exporter access from the monitoring instance
  dynamic "ingress" {
    for_each = toset(data.dns_a_record_set.monitoring.addrs)
    content {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
      description = "node_exporter from monitoring.infra.rust-lang.org"
    }
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
    Name = "rust-prod-playground"
  }
}

resource "aws_network_interface" "playground2" {
  subnet_id       = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets[0]
  security_groups = [aws_security_group.playground.id]
}

resource "aws_eip_association" "playground2" {
  network_interface_id = aws_network_interface.playground2.id
  allocation_id        = aws_eip.playground2.id
}

data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "playground2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "play-2.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.playground2.public_ip]
  ttl     = 60
}

// Create the IAM role used by the playground.

resource "aws_iam_role" "playground" {
  name = "playground"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "s3:ListBucket"
          Resource = aws_s3_bucket.artifacts.arn
        },
        {
          Effect   = "Allow"
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.artifacts.arn}/*"
        },
      ]
    })
  }
}

// Create the EC2 instance itself.

data "aws_ami" "ubuntu24" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_instance_profile" "playground" {
  name = "playground"
  role = aws_iam_role.playground.name
}

resource "aws_instance" "playground2" {
  ami                     = data.aws_ami.ubuntu24.id
  instance_type           = "c5a.large"
  key_name                = data.terraform_remote_state.shared.outputs.master_ec2_key_pair
  iam_instance_profile    = aws_iam_instance_profile.playground.name
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.playground2.id
    device_index         = 0
  }

  tags = {
    Name    = "play-2"
    Service = "playground"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}

resource "aws_cloudwatch_metric_alarm" "reboot" {
  alarm_name        = "playground-status-check"
  alarm_description = "Alarms when playground instance is down"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    InstanceId = aws_instance.playground2.id
  }

  actions_enabled = true
  alarm_actions   = ["arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"]
}

data "aws_region" "current" {}
