output "id" {
  value       = aws_vpc.vpc.id
  description = "ID of the VPC"
}

output "cidr" {
  value       = var.ipv4_cidr
  description = "CIDR of the VPC"
}

output "public_subnets" {
  value       = [for count, subnet in aws_subnet.public : subnet.id]
  description = "IDs of the public subnets inside the VPC"
}

output "private_subnets" {
  value       = [for count, subnet in aws_subnet.private : subnet.id]
  description = "IDs of the private subnets inside the VPC"
}

output "untrusted_subnets" {
  value       = [for count, subnet in aws_subnet.untrusted : subnet.id]
  description = "IDs of the untrusted subnets inside the VPC"
}

output "bastion_security_group_id" {
  value       = module.bastion.security_group_id
  description = "Id of the security group for the bastion instance"
}
