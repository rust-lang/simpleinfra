// L-9F9F275C is the regional "Running Dedicated m9g Hosts" quota.
// Dedicated hosts are limited by host count per instance family.
// New accounts default to zero M9g hosts, so this request must be approved before AWS
// can allocate the billable physical server.
resource "aws_servicequotas_service_quota" "m9g_hosts" {
  service_code = "ec2"
  quota_code   = "L-9F9F275C"
  value        = 1
}
