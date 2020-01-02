resource "aws_vpc" "vpc" {
  cidr_block                       = var.ipv4_cidr
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.name
  }
}
