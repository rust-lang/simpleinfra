output "requested_value" {
  description = "Requested regional Running Dedicated m9g Hosts quota"
  value       = aws_servicequotas_service_quota.m9g_hosts.value
}
