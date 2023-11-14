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


resource "datadog_role" "contributor" {
  name = "Contributor"

  dynamic "permission" {
    for_each = toset([
      data.datadog_permissions.all.permissions.logs_read_index_data,
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

# This is a marker role that is applied to users on top of their other roles.
# It grants access to the log assets for crates.io.
resource "datadog_role" "crates_io" {
  name = "crates.io"
}
