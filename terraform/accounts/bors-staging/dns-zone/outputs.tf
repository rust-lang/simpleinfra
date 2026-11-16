output "name" {
  value       = module.dns_zone.name
  description = "The name of the DNS zone"
}

output "id" {
  value       = module.dns_zone.id
  description = "The id of the DNS zone"
}
