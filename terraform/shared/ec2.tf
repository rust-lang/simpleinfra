data "aws_ami" "ubuntu_bionic" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "buildbot_west_slave_key" {
  key_name   = "buildbot-west-slave-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdGoRV9XPamZwqCMr4uk1oHWPnknzwOOSjuRBnu++WRkn7TtCM4ndDfqtKnvzlX5mzPhdvO1KKx1K8TiJ3wiq7WS4AFLGKQmPHWjg8qxGW7x4S8DHrb4ctmaujZ1+XCNSK3nsCl1lLW8DOrRlKbfeHIAllbMBZxIRmQ+XICVvhKAmSmxzTmYC8tBqvqQprG/uIuKonjLxL/ljtBxXBNECXl/JFCYG0AsB0aiuiMVeHLVzMiEppQ7YP/5Ml1Rpmn6h0dDzFtoD7xenroS98BIQF5kQWhakHbtWcNMz7DVFghWgi9wYr0gtoIshhqWYorC4yJq6HGXd0qdNHuLWNz39h buildbot-west-slave-key.pem"
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}

data "dns_a_record_set" "bastion" {
  host = "bastion.infra.rust-lang.org"
}

resource "aws_security_group" "legacy_common" {
  vpc_id      = aws_vpc.legacy.id
  name        = "rust-prod-common"
  description = "Common rules for all our instances"

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
    for_each = toset(data.dns_a_record_set.monitoring.addrs)
    content {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      cidr_blocks = ["${ingress.value}/32"]
      description = "node_exporter from monitoring"
    }
  }

  tags = {
    Name = "rust-prod-common"
  }
}

resource "aws_security_group" "legacy_http" {
  vpc_id      = aws_vpc.legacy.id
  name        = "rust-prod-http"
  description = "Inbound access for HTTP and HTTPS requests"

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

  tags = {
    Name = "rust-prod-http"
  }
}
