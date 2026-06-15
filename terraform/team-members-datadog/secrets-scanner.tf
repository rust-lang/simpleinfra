locals {
  secrets_scanner_access = local.foundation
}

resource "datadog_role" "secrets_scanner_access" {
  name = "Secrets Scanner Access"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.data_scanner_read,
      data.datadog_permissions.all.permissions.data_scanner_unmask,
      data.datadog_permissions.all.permissions.data_scanner_write,

    ])

    content {
      id = permission.value
    }
  }
}
