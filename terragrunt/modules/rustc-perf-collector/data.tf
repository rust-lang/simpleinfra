locals {
  // An M9g Dedicated Host has two metal-48xl slots. Use both slots so each
  // collector gets direct access to one of the host's Graviton 5 sockets.
  instance_count  = 2
  instance_family = "m9g"
  instance_type   = "m9g.metal-48xl"

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
