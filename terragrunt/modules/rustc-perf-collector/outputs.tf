output "instance_ids" {
  description = "EC2 instance IDs of the Graviton 5 collectors"
  value       = aws_instance.collector[*].id
}

output "dedicated_host_id" {
  description = "EC2 Dedicated Host containing the collectors"
  value       = aws_ec2_host.collector.id
}

output "perf_check_marker" {
  description = "File created by cloud-init after hardware counters pass their smoke test"
  value       = "/var/lib/rustc-perf/perf-counters-ready"
}
