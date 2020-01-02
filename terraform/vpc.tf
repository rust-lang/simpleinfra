module "vpc_prod" {
  source = "./modules/vpc"

  name      = "rust-prod"
  ipv4_cidr = "10.0.0.0/16"

  subnets_public = {
    0 = "usw1-az1",
    1 = "usw1-az3",
  }
  subnets_private = {
    2 = "usw1-az1",
    3 = "usw1-az3",
  }
}

// This defines the legacy VPC, used before we switched to Terraform. Old
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
