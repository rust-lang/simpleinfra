// The internet gateway allows communication from and to the Internet, on both
// IPv4 and IPv6. It's used by public subnets.

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

// The egress-only internet gateway allows only IPv6 connections to the
// Internet. IPv4 connections or IPv6 connections from the internet are not
// supported. It's used by private subnets.

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.vpc.id
}

// The gateway endpoints allow requests to S3 and DynamoDB from private subnets
// without going through the NAT gateway.

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "S3 VPC Endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "DynamoDB VPC Endpoint"
  }
}

// The NAT gateway allows IPv4 connections to the public internet in private
// subnets, without allowing inbound connections. A NAT gateway is created
// inside the first public subnet of each AZ.

resource "aws_eip" "nat" {
  for_each = toset(values(var.private_subnets)) # Name of the AZs

  domain = "vpc"
  tags = {
    Name = "${var.name}--nat-${each.value}"
  }
}

locals {
  # Transform a map of public subnet numbers and AZ names:
  #
  #   {"0" = "usw1-az1", "1" = "usw1-az3", "2" = "usw1-az1", "3" = "usw1-az3"}
  #
  # ...into a map of AZ names and the first subnet number in that AZ:
  #
  #   {"usw1-az1" = "0", "usw1-az3" = "1"}
  #
  az_to_public_subnet = {
    for az, subnets in transpose({
      for num, az in var.public_subnets : num => [az]
    }) : az => subnets[0]
  }

  # Same as above but for private subnets
  az_to_private_subnet = {
    for az, subnets in transpose({
      for num, az in var.private_subnets : num => [az]
    }) : az => subnets[0]
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = local.az_to_private_subnet

  subnet_id     = aws_subnet.public[local.az_to_public_subnet[each.key]].id
  allocation_id = aws_eip.nat[each.key].id

  tags = {
    Name = "${var.name}--nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.igw]
}

module "bastion" {
  source           = "../bastion"
  vpc_id           = aws_vpc.vpc.id
  public_subnet_id = aws_subnet.public[0].id
  zone_id          = var.zone_id
}
