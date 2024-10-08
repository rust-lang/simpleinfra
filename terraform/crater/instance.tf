locals {
  domains           = ["crater.rust-lang.org"]
  top_level_domains = { for domain in local.domains : domain => join(".", reverse(slice(reverse(split(".", domain)), 0, 2))) }
  cluster_config    = data.terraform_remote_state.shared.outputs.ecs_cluster_config
}

module "certificate" {
  source  = "../shared/modules/acm-certificate"
  domains = local.domains
}

resource "aws_lb_listener_certificate" "service" {
  listener_arn    = local.cluster_config.lb_listener_arn
  certificate_arn = module.certificate.arn
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = local.cluster_config.lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    host_header {
      values = local.domains
    }
  }
}

resource "aws_lb_target_group" "service" {
  name        = "crater-${substr(uuid(), 0, 10)}"
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  target_type = "instance"

  port     = 80
  protocol = "HTTP"

  deregistration_delay = 30
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "aws_eip" "crater" {
  vpc = true
  tags = {
    Name = "crater"
  }
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

data "dns_a_record_set" "bastion" {
  host = "bastion.infra.rust-lang.org"
}

data "dns_a_record_set" "bastion2" {
  host = "bastion2.infra.rust-lang.org"
}

resource "aws_security_group" "crater" {
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name        = "rust-prod-crater"
  description = "Access rules for the production crater instance."

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

  dynamic "ingress" {
    for_each = toset(data.dns_a_record_set.bastion2.addrs)
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
      description = "SSH from the bastion"
    }
  }

  dynamic "ingress" {
    for_each = toset(data.dns_a_record_set.bastion2.addrs)
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
    Name = "rust-prod-crater"
  }
}

resource "aws_network_interface" "crater" {
  subnet_id       = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets[0]
  security_groups = [aws_security_group.crater.id]
}

resource "aws_eip_association" "crater" {
  network_interface_id = aws_network_interface.crater.id
  allocation_id        = aws_eip.crater.id
}

data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "crater" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "crater.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.crater.public_ip]
  ttl     = 60
}

// Create the IAM role used by the crater.

resource "aws_iam_role" "crater" {
  name = "crater"

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
}


resource "aws_iam_policy" "s3_access" {
  name = "crater-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectACL",
          "s3:GetObject",
          "s3:GetObjectACL",
          "s3:GetBucketLocation",
          "s3:CreateMultipartUpload",
          "s3:UploadPart",
          "s3:CompleteMultipartUpload",
          "s3:AbortMultipartUpload",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::crater-reports/*",
          "arn:aws:s3:::crater-reports"
        ]
      },
      {
        Effect = "Allow"
        Action = "s3:DeleteObject"
        Resource = [
          "arn:aws:s3:::crater-reports/backup/*",
          "arn:aws:s3:::crater-reports"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.crater.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ci_pull" {
  role       = aws_iam_role.crater.name
  policy_arn = module.ecr.policy_pull_arn
}

// Create the EC2 instance itself.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_instance_profile" "crater" {
  name = "crater"
  role = aws_iam_role.crater.name
}

resource "aws_instance" "crater" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "m6a.large"
  key_name                = data.terraform_remote_state.shared.outputs.master_ec2_key_pair
  iam_instance_profile    = aws_iam_instance_profile.crater.name
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.crater.id
    device_index         = 0
  }

  tags = {
    Name = "crater"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}

resource "aws_lb_target_group_attachment" "crater" {
  target_group_arn = aws_lb_target_group.service.arn
  target_id        = aws_instance.crater.id
  port             = 80
}

data "aws_route53_zone" "zones" {
  // Convert foo.bar.baz into bar.baz
  for_each = toset(values(local.top_level_domains))
  name     = each.value
}

resource "aws_route53_record" "service" {
  for_each = toset(local.domains)

  zone_id = data.aws_route53_zone.zones[local.top_level_domains[each.value]].id
  name    = each.value
  type    = "CNAME"
  ttl     = 300
  records = [local.cluster_config.lb_dns_name]
}
