output "instance_id" {
  description = "EC2 instance ID of the Graviton 5 collector"
  value       = aws_instance.collector.id
}

output "dedicated_host_id" {
  description = "EC2 Dedicated Host containing the collector"
  value       = aws_ec2_host.collector.id
}

output "instance_type" {
  description = "EC2 instance type of the collector"
  value       = aws_instance.collector.instance_type
}

output "availability_zone" {
  description = "Availability Zone selected for the collector"
  value       = aws_instance.collector.availability_zone
}

output "perf_check_marker" {
  description = "File created by cloud-init after hardware counters pass their smoke test"
  value       = "/var/lib/rustc-perf/perf-counters-ready"
}
