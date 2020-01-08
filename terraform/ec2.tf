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

data "aws_ssm_parameter" "buildbot_west_slave_key" {
  name            = "/buildabot/ec2_key/public"
  with_decryption = true
}

resource "aws_key_pair" "buildbot_west_slave_key" {
  key_name   = "buildbot-west-slave-key"
  public_key = data.aws_ssm_parameter.buildbot_west_slave_key.value
}

resource "aws_security_group" "legacy_common" {
  vpc_id      = aws_vpc.legacy.id
  name        = "rust-prod-common"
  description = "Common rules for all our instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${module.service_bastion.ip}/32"]
    description = "SSH from the bastion"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${module.service_bastion.ip}/32"]
    description = "ICMP from the bastion"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["52.9.166.219/32"]
    description = "node_exporter from monitoring"
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
