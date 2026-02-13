// The resources in this file setup the EC2 instance of the bastion.

// Associate an elastic IP to the instance.

resource "aws_eip" "bastion" {
  domain = "vpc"
  tags = {
    Name = "bastion"
  }
}

resource "aws_network_interface" "bastion" {
  subnet_id       = var.public_subnet_id
  security_groups = [aws_security_group.bastion.id]
}

resource "aws_eip_association" "bastion" {
  network_interface_id = aws_network_interface.bastion.id
  allocation_id        = aws_eip.bastion.id
}

// Create the bastion DNS record.

data "aws_route53_zone" "zone" {
  zone_id = var.zone_id
}

resource "aws_route53_record" "bastion" {
  zone_id = var.zone_id
  name    = "bastion.${data.aws_route53_zone.zone.name}"
  type    = "A"
  records = [aws_eip.bastion.public_ip]
  ttl     = 300
}

// Create the EC2 instance itself.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

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

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.micro"
  ebs_optimized = true
  monitoring    = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.bastion.id
  }

  tags = {
    Name = "bastion"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}
