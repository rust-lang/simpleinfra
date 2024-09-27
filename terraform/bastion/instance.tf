// The resources in this file setup the EC2 instance of the bastion.

// Associate an elastic IP to the instance.

resource "aws_eip" "bastion" {
  vpc = true
  tags = {
    Name = "bastion"
  }
}

resource "aws_eip" "bastion2" {
  domain = "vpc"
  tags = {
    Name = "bastion2"
  }
}

resource "aws_network_interface" "bastion" {
  subnet_id       = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets[0]
  security_groups = [aws_security_group.bastion.id]
}

resource "aws_network_interface" "bastion2" {
  subnet_id       = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets[0]
  security_groups = [aws_security_group.bastion.id]
}

resource "aws_eip_association" "bastion" {
  network_interface_id = aws_network_interface.bastion.id
  allocation_id        = aws_eip.bastion.id
}

resource "aws_eip_association" "bastion2" {
  network_interface_id = aws_network_interface.bastion2.id
  allocation_id        = aws_eip.bastion2.id
}

// Create the bastion.infra.rust-lang.org DNS record.

data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "bastion.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.bastion.public_ip]
  ttl     = 300
}

resource "aws_route53_record" "bastion2" {
  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "bastion2.infra.rust-lang.org"
  type    = "A"
  records = [aws_eip.bastion.public_ip]
  ttl     = 300
}

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

resource "aws_instance" "bastion" {
  ami                     = data.aws_ami.ubuntu_bionic.id
  instance_type           = "t3a.micro"
  key_name                = data.terraform_remote_state.shared.outputs.master_ec2_key_pair
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.bastion.id
    device_index         = 0
  }

  tags = {
    Name = "bastion"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}

resource "aws_instance" "bastion2" {
  ami                     = data.aws_ami.ubuntu24.id
  instance_type           = "t3a.micro"
  key_name                = data.terraform_remote_state.shared.outputs.master_ec2_key_pair
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.bastion2.id
    device_index         = 0
  }

  tags = {
    Name    = "bastion2"
    Service = "bastion"
  }

  lifecycle {
    # Don't recreate the instance automatically when the AMI changes.
    ignore_changes = [ami]
  }
}
