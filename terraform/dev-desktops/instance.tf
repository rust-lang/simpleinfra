resource "aws_eip" "dev_desktop" {
  vpc = true
  tags = {
    Name = "dev_desktop"
  }
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

data "aws_security_group" "bastion" {
  vpc_id = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name   = "rust-prod-bastion"
}

resource "aws_security_group" "dev_desktop" {
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name        = "rust-prod-dev_desktop"
  description = "Access rules for the production dev_desktop instance."

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
    from_port        = 8
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
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
    Name = "rust-prod-dev_desktop"
  }
}

resource "aws_network_interface" "dev_desktop" {
  subnet_id       = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets[0]
  security_groups = [aws_security_group.dev_desktop.id]
}

resource "aws_eip_association" "dev_desktop" {
  network_interface_id = aws_network_interface.dev_desktop.id
  allocation_id        = aws_eip.dev_desktop.id
}

data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "dev_desktop" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "dev-desktop.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.dev_desktop.public_ip]
  ttl     = 60
}

// Create the IAM role used by the dev-desktop.

// Create the EC2 instance itself.

data "aws_ami" "ubuntu_bionic" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "dev_desktop" {
  ami                     = data.aws_ami.ubuntu_bionic.id
  instance_type           = "c5a.8xlarge"
  key_name                = data.terraform_remote_state.shared.outputs.master_ec2_key_pair
  ebs_optimized           = true
  disable_api_termination = false
  monitoring              = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 500
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.dev_desktop.id
    device_index         = 0
  }

  tags = {
    Name = "dev-desktop"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}
