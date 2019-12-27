// This file defines the legacy VPC, used before we switched to Terraform. Old
// resources are still attached to it, but newer ones should be moved to the
// rust-prod VPC.

resource "aws_vpc" "legacy" {
  cidr_block = "172.30.0.0/16"

  tags = {
    Name = "rust-legacy"
  }
}

resource "aws_subnet" "legacy" {
  vpc_id                  = aws_vpc.legacy.id
  cidr_block              = "172.30.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "rust-legacy"
  }
}
