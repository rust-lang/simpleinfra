output "name" {
  value       = aws_route53_zone.zone.name
  description = "The name of the DNS zone"
}

output "id" {
  value       = aws_route53_zone.zone.id
  description = "The id of the DNS zone"
}
