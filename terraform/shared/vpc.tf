module "vpc_prod" {
  source = "./modules/vpc"

  name      = "rust-prod"
  ipv4_cidr = "10.0.0.0/16"

  public_subnets = {
    0 = "usw1-az1",
    1 = "usw1-az3",
  }
  private_subnets = {
    2 = "usw1-az1",
    3 = "usw1-az3",
  }
  untrusted_subnets = {
    4 = "usw1-az1",
    5 = "usw1-az3",
  }

  peering = {
    (aws_vpc.legacy.cidr_block) = aws_vpc_peering_connection.legacy_with_prod.id
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

resource "aws_internet_gateway" "legacy" {
  vpc_id = aws_vpc.legacy.id
}

resource "aws_route_table" "legacy" {
  vpc_id = aws_vpc.legacy.id

  route {
    cidr_block                = module.vpc_prod.cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.legacy_with_prod.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.legacy.id
  }
}

// Setup peering between the legacy vpc and the prod vpc. This is needed so
// that the legacy docs.rs instance can conect to the database inside the prod
// instance.

resource "aws_vpc_peering_connection" "legacy_with_prod" {
  vpc_id      = aws_vpc.legacy.id
  peer_vpc_id = module.vpc_prod.id
  auto_accept = true
}
