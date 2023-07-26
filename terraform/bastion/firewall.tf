// The resources in this file control who has access to the bastion server.

locals {
  // Users allowed to connect to the bastion through SSH. Each user needs to
  // have the CIDR of the static IP they want to connect from stored in AWS SSM
  // Parameter Store (us-west-1), in a string key named:
  //
  //     /prod/bastion/allowed-ips/${user}
  //
  allowed_users = [
    "aidanhs",
    "joshua",
    "pietro",
    "shep",
    "simulacrum",
    "technetos",
    "nemo157",
    "syphar",
    "rylev",
    "rylev-ip-2",
    "jdn",
    "guillaumegomez",
  ]
}

// Security group to prevent unauthorized access to the bastion.

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

data "aws_ssm_parameter" "allowed_ips" {
  for_each = toset(local.allowed_users)
  name     = "/prod/bastion/allowed-ips/${each.value}"
}

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

  // SSH access from the allowed users
  dynamic "ingress" {
    for_each = toset(local.allowed_users)
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
    for_each = toset(local.allowed_users)
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
    Name = "rust-prod-bastion"
  }
}
