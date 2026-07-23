# Fetch all available permissions
data "datadog_permissions" "all" {
  include_restricted = true
}
