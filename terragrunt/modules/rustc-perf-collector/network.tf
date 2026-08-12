// This service needs one outbound-only host, so a small dedicated VPC is easier
// to reason about than adopting a default VPC or deploying the multi-AZ/NAT
// topology used by web services.
resource "aws_vpc" "collector" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rustc-perf-prod"
  }
}

resource "aws_internet_gateway" "collector" {
  vpc_id = aws_vpc.collector.id

  tags = {
    Name = "rustc-perf-prod"
  }
}

resource "aws_subnet" "collector" {
  availability_zone_id    = local.availability_zone_id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.collector.id

  tags = {
    Name = "rustc-perf-prod"
  }
}

resource "aws_route_table" "collector" {
  vpc_id = aws_vpc.collector.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.collector.id
  }

  tags = {
    Name = "rustc-perf-prod"
  }
}

resource "aws_route_table_association" "collector" {
  route_table_id = aws_route_table.collector.id
  subnet_id      = aws_subnet.collector.id
}

// Deliberately define no ingress rules. SSM establishes its management channel
// outbound, so neither SSH nor a bastion needs to be exposed to the internet.
resource "aws_security_group" "collector" {
  name        = "rustc-perf-collector"
  description = "No-ingress security group for the rustc-perf collector"
  vpc_id      = aws_vpc.collector.id

  tags = {
    Name = "rustc-perf-collector"
  }
}

resource "aws_vpc_security_group_egress_rule" "collector" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow the collector to fetch toolchains and benchmark sources"
}
