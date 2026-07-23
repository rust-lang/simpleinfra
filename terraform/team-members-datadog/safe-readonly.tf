# Opt out of all default permissions and grant
# only the observability access needed to debug incidents and troubleshoot issues.
# This role can be used by AI agents to access DataDog.
resource "datadog_role" "safe_readonly" {
  name = "safe-readonly"

  # The managed Datadog Read Only Role provides read access to unrelated products
  # that can contain sensitive data.
  default_permissions_opt_out = true

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.dashboards_read,
      data.datadog_permissions.all.permissions.apm_read,
      data.datadog_permissions.all.permissions.monitors_read,
    ])

    content {
      id = permission.value
    }
  }
}
