// VPC

resource "aws_vpc" "main" {
  cidr_block                       = "10.2.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true

  tags = {
    Name = "arm-ci"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"

  cidr_block      = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "arm-ci-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "arm-ci-public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
