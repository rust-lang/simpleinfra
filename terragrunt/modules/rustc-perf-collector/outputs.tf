output "instance_id" {
  description = "EC2 instance ID of the Graviton 5 collector"
  value       = aws_instance.collector.id
}

output "public_ip" {
  description = "Stable Elastic IPv4 address of the Graviton 5 collector"
  value       = aws_eip.collector.public_ip
}

output "public_ipv6" {
  description = "Stable public IPv6 address of the Graviton 5 collector"
  value       = aws_instance.collector.ipv6_addresses[0]
}
