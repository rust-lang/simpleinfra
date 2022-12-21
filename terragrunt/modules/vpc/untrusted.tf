// Define the untrusted subnets inside the VPC.
//
// Resources inside these subnets can't be reached from the Internet, and can
// only communicate with the public subnet or (egress only) the Internet.
// Reaching resources inside the private subnet or other resources inside an
// untrusted subnet is blocked.

resource "aws_subnet" "untrusted" {
  for_each = var.untrusted_subnets

  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, parseint(each.key, 10))
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, parseint(each.key, 10))

  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true
  availability_zone_id            = each.value

  tags = {
    Name = "${var.name}--untrusted-${each.key}"
  }
}

// By default subnets don't have any kind of internet access available, but can
// only communicate with other hosts inside the same VPC. This creates a new
// route table, forwarding public routes to the NAT gateway (IPv4) or the
// egress-only internet gateway (IPv6), both created in gateways.tf. The route
// table is then attached to all the untrusted subnets.

resource "aws_route_table" "untrusted" {
  for_each = toset(values(var.untrusted_subnets))

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.value].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
  }

  tags = {
    Name = "${var.name}--untrusted-${each.value}"
  }
}

resource "aws_route_table_association" "untrusted" {
  for_each = var.untrusted_subnets

  subnet_id      = aws_subnet.untrusted[each.key].id
  route_table_id = aws_route_table.untrusted[each.value].id
}

// The VPC Endpoint Gateways for S3 and DynamoDB are attached to the route
// tables. These gateways, defined in gateways.tf, allow traffic to reach those
// services directly, without going through the NAT gateway. This reduces our
// bill, as data going through the NAT gateway is not free.

resource "aws_vpc_endpoint_route_table_association" "untrusted_s3" {
  for_each = toset(values(var.untrusted_subnets))

  route_table_id  = aws_route_table.untrusted[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "untrusted_dynamodb" {
  for_each = toset(values(var.untrusted_subnets))

  route_table_id  = aws_route_table.untrusted[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}

// This Network ACL isolates instances in the untrusted subnet from each other
// and from instances in the private subnets, while still allowing requests to
// the public subnet or outgoing connections to the Internet.

resource "aws_network_acl" "untrusted" {
  count      = length(var.untrusted_subnets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [for subnet, az in var.untrusted_subnets : aws_subnet.untrusted[subnet].id]

  // The first rules are denying ingress and egress communication from and to
  // the private and untrusted subnets, across IPv4 and IPv6.

  dynamic "ingress" {
    for_each = merge(
      { for subnet in keys(var.private_subnets) : subnet => aws_subnet.private[subnet] },
      { for subnet in keys(var.untrusted_subnets) : subnet => aws_subnet.untrusted[subnet] },
    )
    content {
      rule_no = ingress.key * 2
      action  = "deny"

      protocol   = "all"
      from_port  = 0
      to_port    = 0
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "ingress" {
    for_each = merge(
      { for subnet in keys(var.private_subnets) : subnet => aws_subnet.private[subnet] },
      { for subnet in keys(var.untrusted_subnets) : subnet => aws_subnet.untrusted[subnet] },
    )
    content {
      rule_no = ingress.key * 2 + 1
      action  = "deny"

      protocol        = "all"
      from_port       = 0
      to_port         = 0
      ipv6_cidr_block = ingress.value.ipv6_cidr_block
    }
  }

  dynamic "egress" {
    for_each = merge(
      { for subnet in keys(var.private_subnets) : subnet => aws_subnet.private[subnet] },
      { for subnet in keys(var.untrusted_subnets) : subnet => aws_subnet.untrusted[subnet] },
    )
    content {
      rule_no = egress.key * 2
      action  = "deny"

      protocol   = "all"
      from_port  = 0
      to_port    = 0
      cidr_block = egress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = merge(
      { for subnet in keys(var.private_subnets) : subnet => aws_subnet.private[subnet] },
      { for subnet in keys(var.untrusted_subnets) : subnet => aws_subnet.untrusted[subnet] },
    )
    content {
      rule_no = egress.key * 2 + 1
      action  = "deny"

      protocol        = "all"
      from_port       = 0
      to_port         = 0
      ipv6_cidr_block = egress.value.ipv6_cidr_block
    }
  }

  // Then we allow connections to the rest of the network:
  //
  // - Communications from and to instances inside a public subnet will be
  //   allowed, both as ingress and as egress.
  //
  // - Outgoing communications to the Interned will be allowed. While in theory
  //   this ACL also allows inbound connections from the Internet, in practice
  //   that's not possible as all untrusted subnets are behind NAT. Unfortunately
  //   it's not possible to deny incoming connections from the ACL, as Network
  //   ACLs are stateless so we need to keep the ports open to allow responses
  //   to come through.

  ingress {
    rule_no = 1000
    action  = "allow"

    protocol   = "all"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no = 1001
    action  = "allow"

    protocol        = "all"
    from_port       = 0
    to_port         = 0
    ipv6_cidr_block = "::/0"
  }

  egress {
    rule_no = 1000
    action  = "allow"

    protocol   = "all"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no = 1001
    action  = "allow"

    protocol        = "all"
    from_port       = 0
    to_port         = 0
    ipv6_cidr_block = "::/0"
  }

  tags = {
    Name = "${var.name}--untrusted"
  }
}
