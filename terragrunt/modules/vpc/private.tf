// Define the private subnets inside the VPC.
//
// Resources inside these subnets can't be reached from the Internet, and can
// only communicate with the Internet through a NAT Gateway.

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, parseint(each.key, 10))
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, parseint(each.key, 10))

  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true
  availability_zone_id            = each.value

  tags = {
    Name = "${var.name}--private-${each.key}"
  }
}

// By default subnets don't have any kind of internet access available, but can
// only communicate with other hosts inside the same VPC. This creates a new
// route table, forwarding public routes to the NAT gateway (IPv4) or the
// egress-only internet gateway (IPv6), both created in gateways.tf. The route
// table is then attached to all the private subnets.

resource "aws_route_table" "private" {
  for_each = toset(values(var.private_subnets))

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.value].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
  }

  dynamic "route" {
    for_each = var.peering
    content {
      cidr_block                = route.key
      vpc_peering_connection_id = route.value
    }
  }

  tags = {
    Name = "${var.name}--private-${each.value}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value].id
}

// The VPC Endpoint Gateways for S3 and DynamoDB are attached to the route
// tables. These gateways, defined in gateways.tf, allow traffic to reach those
// services directly, without going through the NAT gateway. This reduces our
// bill, as data going through the NAT gateway is not free.

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  for_each = toset(values(var.private_subnets))

  route_table_id  = aws_route_table.private[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  for_each = toset(values(var.private_subnets))

  route_table_id  = aws_route_table.private[each.value].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}
