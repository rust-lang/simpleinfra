// Instances

resource "aws_eip" "dev_desktop" {
  for_each = var.instances

  vpc = true

  tags = {
    Name = each.key
  }
}

resource "aws_eip_association" "dev_desktop" {
  for_each = var.instances

  instance_id   = aws_instance.instance[each.key].id
  allocation_id = aws_eip.dev_desktop[each.key].id
}

resource "aws_instance" "instance" {
  for_each = var.instances

  ami                     = data.aws_ami.instance[each.value.instance_arch].id
  instance_type           = each.value.instance_type
  key_name                = aws_key_pair.instance.key_name
  ebs_optimized           = true
  disable_api_termination = false
  monitoring              = false
  subnet_id               = aws_subnet.public.id
  vpc_security_group_ids  = [aws_security_group.dev_desktops.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.storage
    delete_on_termination = true
    tags = {
      Name = each.key
    }
  }

  tags = {
    Name = each.key
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}

data "aws_ami" "instance" {
  for_each = toset(values(var.instances)[*].instance_arch)

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-${each.key}-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// Security groups

resource "aws_security_group" "dev_desktops" {
  vpc_id      = aws_vpc.main.id
  name        = "dev-desktops"
  description = "Access rules for dev-desktops instances."

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
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "SSH access from the world"
  }

  ingress {
    from_port        = 60000
    to_port          = 61000
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Mosh access from the world"
  }

  ingress {
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Ping access from the world"
  }

  ingress {
    from_port        = 8
    to_port          = -1
    protocol         = "icmpv6"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Ping access from the world"
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
    Name = "dev-desktops"
  }
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

// DNS records

data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "ipv4" {
  for_each = var.instances

  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "${each.key}.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.dev_desktop[each.key].public_ip]
  ttl     = 60
}

resource "aws_route53_record" "ipv6" {
  for_each = var.instances

  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "${each.key}.infra.rust-lang.org"
  type    = "AAAA"
  records = aws_instance.instance[each.key].ipv6_addresses
  ttl     = 60
}

// Key pairs

resource "aws_key_pair" "instance" {
  key_name   = "dev-desktops-buildbot-west-slave-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdGoRV9XPamZwqCMr4uk1oHWPnknzwOOSjuRBnu++WRkn7TtCM4ndDfqtKnvzlX5mzPhdvO1KKx1K8TiJ3wiq7WS4AFLGKQmPHWjg8qxGW7x4S8DHrb4ctmaujZ1+XCNSK3nsCl1lLW8DOrRlKbfeHIAllbMBZxIRmQ+XICVvhKAmSmxzTmYC8tBqvqQprG/uIuKonjLxL/ljtBxXBNECXl/JFCYG0AsB0aiuiMVeHLVzMiEppQ7YP/5Ml1Rpmn6h0dDzFtoD7xenroS98BIQF5kQWhakHbtWcNMz7DVFghWgi9wYr0gtoIshhqWYorC4yJq6HGXd0qdNHuLWNz39h"
}
