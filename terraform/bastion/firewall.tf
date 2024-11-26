// The resources in this file control who has access to the bastion server.

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

// Security group to prevent unauthorized access to the bastion.
resource "aws_security_group" "bastion" {
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name        = "rust-prod-bastion"
  description = "Access rules for the production bastion instance."

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
    Name = "rust-prod-bastion"
  }
}
