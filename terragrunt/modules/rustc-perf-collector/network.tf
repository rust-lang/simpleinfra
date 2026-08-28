resource "aws_default_vpc" "collector" {
  assign_generated_ipv6_cidr_block = true
}

# Adopt the default subnet in the collector's availability zone, assign it an IPv6
# /64, and use it as the network in which the collector instance is launched.
resource "aws_default_subnet" "collector" {
  availability_zone = local.availability_zone
  ipv6_cidr_block   = cidrsubnet(aws_default_vpc.collector.ipv6_cidr_block, 8, 0)
}

# Look up the internet gateway that AWS creates for the default VPC so it can be
# used as the target of the collector subnet's IPv6 default route.
data "aws_internet_gateway" "collector" {
  filter {
    name   = "attachment.vpc-id"
    values = [aws_default_vpc.collector.id]
  }
}

# Route all IPv6 traffic through the default VPC's internet gateway, giving the
# collector instance outbound IPv6 connectivity and making allowed ingress routable.
resource "aws_route" "collector_ipv6" {
  route_table_id              = aws_default_vpc.collector.default_route_table_id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = data.aws_internet_gateway.collector.id
}

# Security group attached to the collector instance; with ingress and egress rule resources declared below.
resource "aws_security_group" "collector" {
  name        = "rustc-perf-collector"
  description = "SSH access and egress for the rustc-perf collector"
  vpc_id      = aws_default_vpc.collector.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH access"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ipv6" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH access"
}

resource "aws_vpc_security_group_ingress_rule" "ping" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8
  to_port           = -1
  ip_protocol       = "icmp"
  description       = "Ping access"
}

resource "aws_vpc_security_group_ingress_rule" "ping_ipv6" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv6         = "::/0"
  from_port         = 128
  to_port           = -1
  ip_protocol       = "icmpv6"
  description       = "Ping access"
}

resource "aws_vpc_security_group_egress_rule" "collector" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all IPv4 egress traffic."
}

resource "aws_vpc_security_group_egress_rule" "collector_ipv6" {
  security_group_id = aws_security_group.collector.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  description       = "Allow all IPv6 egress traffic."
}
