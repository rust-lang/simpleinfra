// The resources in this file control who has access to the bastion server.


// Security group to prevent unauthorized access to the bastion.

data "aws_ssm_parameter" "allowed_ips" {
  for_each = toset(var.allowed_users)
  name     = "/bastion/allowed-ips/${each.value}"
}

resource "aws_security_group" "bastion" {
  vpc_id      = var.vpc_id
  name        = "bastion-${var.vpc_id}"
  description = "Access rules for the production bastion instance."


  // SSH access from the allowed users
  dynamic "ingress" {
    for_each = toset(var.allowed_users)
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.aws_ssm_parameter.allowed_ips[ingress.value].value]
      description = "SSH access for ${ingress.value}"
    }
  }

  // Ping access from allowed users
  dynamic "ingress" {
    for_each = toset(var.allowed_users)
    content {
      from_port   = 8
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = [data.aws_ssm_parameter.allowed_ips[ingress.value].value]
      description = "Ping access for ${ingress.value}"
    }
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
    Name = "bastion"
  }
}
