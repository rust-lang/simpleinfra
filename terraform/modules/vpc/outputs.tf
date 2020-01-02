output "id" {
  value       = aws_vpc.vpc.id
  description = "ID of the VPC"
}

output "public_subnets" {
  value       = [for count, subnet in aws_subnet.public : subnet.id]
  description = "IDs of the public subnets inside the VPC"
}
