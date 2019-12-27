// This defines the main production VPC for Rust Infrastructure, hosting most
// of our infra pieces. It has a subnet in both of us-west-1's AZs. Both IPv4
// and IPv6 are enabled, with public IPs assigned for both protocols.

locals {
  vpc_prod_azs = ["usw1-az1", "usw1-az3"]
}

resource "aws_vpc" "prod" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "rust-prod"
  }
}

resource "aws_subnet" "prod_public" {
  count = length(local.vpc_prod_azs)

  vpc_id          = aws_vpc.prod.id
  cidr_block      = cidrsubnet(aws_vpc.prod.cidr_block, 8, count.index)
  ipv6_cidr_block = cidrsubnet(aws_vpc.prod.ipv6_cidr_block, 8, count.index)

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone_id            = local.vpc_prod_azs[count.index]

  tags = {
    Name = "${aws_vpc.prod.tags["Name"]}--public-${count.index}"
  }
}

// Enable internet access inside the VPC
//
// By default VPCs don't have any kind of internet access available, but can
// only communicate with other hosts inside the same VPC. The following code
// create an "internet gateway", and a route table to route all the connections
// outside the VPC to that gateway. The route table is then associated with all
// the subnets.

resource "aws_internet_gateway" "prod_public" {
  vpc_id = aws_vpc.prod.id
}

resource "aws_route_table" "prod_public" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_public.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.prod_public.id
  }

  tags = {
    Name = "internet access - ${aws_vpc.prod.tags["Name"]}"
  }
}

resource "aws_route_table_association" "prod_public" {
  count = length(aws_subnet.prod_public)

  subnet_id      = aws_subnet.prod_public[count.index].id
  route_table_id = aws_route_table.prod_public.id
}
