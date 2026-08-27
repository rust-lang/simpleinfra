locals {
  // The project requested the M9g (Graviton 5) family on a Dedicated Host.
  // Start with a 12xlarge partition: it provides 48 vCPUs and 192 GiB while
  // using one of the eight 12xlarge slots listed for an empty M9g host, leaving
  // capacity available for future M9g collectors.
  instance_family = "m9g"
  instance_type   = "m9g.12xlarge"

  availability_zone = "us-east-2a"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
