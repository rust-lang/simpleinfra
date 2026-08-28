// Dedicated hosts are limited by host count per instance family.
// New accounts default to zero M9g hosts, so this request must be approved before AWS
// can allocate the billable physical server.
resource "aws_servicequotas_service_quota" "m9g_hosts" {
  service_code = "ec2"
  # Regional "Running Dedicated m9g Hosts" quota.
  quota_code = "L-9F9F275C"
  value      = 1
}

resource "aws_servicequotas_service_quota" "standard_ondemand_vcpus" {
  service_code = "ec2"
  # Regional "Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances" quota.
  quota_code = "L-1216C47A"
  # vCPU of m9g.metal-48xl.
  value = 192
}
