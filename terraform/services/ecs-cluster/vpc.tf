// The cluster uses its own VPC, separate from the rest of the infrastructure,
// with a subnet in all the availability zones. Both IPv4 and IPv6 is enabled,
// with public IPs assigned to both.

data "aws_availability_zones" "azs" {}

resource "aws_vpc" "cluster" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id          = aws_vpc.cluster.id
  cidr_block      = cidrsubnet(aws_vpc.cluster.cidr_block, 8, count.index)
  ipv6_cidr_block = cidrsubnet(aws_vpc.cluster.ipv6_cidr_block, 8, count.index)

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "${aws_vpc.cluster.tags["Name"]}-${data.aws_availability_zones.azs.names[count.index]}"
  }
}

// Enable internet access inside the VPC
//
// By default VPCs don't have any kind of internet access available, but can
// only communicate with other hosts inside the same VPC. The following code
// create an "internet gateway", and a route table to route all the connections
// outside the VPC to that gateway. The route table is then associated with all
// the subnets.

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.cluster.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.public.id
  }

  tags = {
    Name = "internet access - ${aws_vpc.cluster.tags["Name"]}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
