// Define the public subnets inside the VPC.
//
// Resources inside these subnets can communicate directly to the internet, and
// are publicly reachable (modulo any security group). A public IPv4 is
// associated with each resource as well.

resource "aws_subnet" "public" {
  for_each = var.subnets_public

  vpc_id          = aws_vpc.vpc.id
  cidr_block      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, parseint(each.key, 10))
  ipv6_cidr_block = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, parseint(each.key, 10))

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone_id            = each.value

  tags = {
    Name = "${var.name}--public-${each.key}"
  }
}

// By default subnets don't have any kind of internet access available, but can
// only communicate with other hosts inside the same VPC. This creates a new
// route table, forwarding public routes to the internet gateway created in
// gateways.tf. The route table is then attached to all the public subnets.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name}--public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = var.subnets_public

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}
