# Fetch all available permissions
data "datadog_permissions" "all" {}

resource "datadog_role" "board_member" {
  name = "Board Member"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.dashboards_write,
    ])

    content {
      id = permission.value
    }
  }
}

resource "datadog_role" "crates_io" {
  name = "crates.io"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_data,
      data.datadog_permissions.all.permissions.logs_live_tail,
      data.datadog_permissions.all.permissions.logs_read_archives,
      data.datadog_permissions.all.permissions.dashboards_write,
    ])

    content {
      id = permission.value
    }
  }
}
