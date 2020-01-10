resource "aws_eip" "bastion" {
  vpc = true

  tags = {
    Name = "bastion"
  }
}

data "aws_ssm_parameter" "allowed_ips" {
  for_each = toset(var.allowed_users)
  name     = "/prod/bastion/allowed-ips/${each.value}"
}

resource "aws_security_group" "rust_prod_bastion" {
  vpc_id      = var.vpc_id
  name        = "rust-prod-bastion"
  description = "SSH access to the bastion from whitelisted networks"

  dynamic "ingress" {
    for_each = toset(var.allowed_users)
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.aws_ssm_parameter.allowed_ips[ingress.value].value]
      description = ingress.value
    }
  }

  tags = {
    Name = "rust-prod-bastion"
  }
}

resource "aws_network_interface" "bastion" {
  subnet_id = var.subnet_id
  security_groups = [
    var.common_security_group_id,
    aws_security_group.rust_prod_bastion.id,
  ]

}

resource "aws_instance" "bastion" {
  ami                     = var.ami_id
  instance_type           = "t3a.nano"
  key_name                = var.key_pair
  ebs_optimized           = true
  disable_api_termination = true
  monitoring              = false

  root_block_device {
    volume_type           = "gp2"
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

resource "aws_eip_association" "bastion" {
  network_interface_id = aws_network_interface.bastion.id
  allocation_id        = aws_eip.bastion.id
}
