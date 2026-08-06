# Opt out of all default permissions and grant
# only the observability access needed to debug incidents and troubleshoot issues.
# This role can be used by AI agents to access DataDog.
#
# Risk: if PII or secrets leak into logs, this role can read them.
# If you use an AI agent, consider writing in the prompt something like:
# "if you find PII or secrets in logs, stop your task and report it to me,
# so that I audit them and I decide whether to remove them".
resource "datadog_role" "safe_readonly" {
  name = "safe-readonly"

  # The managed Datadog Read Only Role provides read access to unrelated products
  # that can contain sensitive data.
  default_permissions_opt_out = true

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.apm_read,
      data.datadog_permissions.all.permissions.dashboards_read,
      data.datadog_permissions.all.permissions.incident_notification_settings_read,
      data.datadog_permissions.all.permissions.incident_read,
      data.datadog_permissions.all.permissions.incident_settings_read,
      data.datadog_permissions.all.permissions.integrations_read,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.logs_read_config,
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_read_index_data,
      data.datadog_permissions.all.permissions.monitors_read,
      data.datadog_permissions.all.permissions.notebooks_read,
      data.datadog_permissions.all.permissions.on_call_read,
      data.datadog_permissions.all.permissions.slos_read,
    ])

    content {
      id = permission.value
    }
  }
}
