locals {
  databases = [
    "triagebot",
    "rustc_perf",
  ]
}

resource "random_password" "users" {
  for_each = toset(local.databases)

  length           = 25
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "users" {
  for_each = toset(local.databases)

  name     = each.value
  login    = true
  password = random_password.users[each.value].result

  # The role doesn't have the permission to do this, and we don't really need
  # this functionality. If this is set to `false`, deleting the role will fail.
  skip_reassign_owned = true
}

resource "postgresql_grant" "rw_self_tables" {
  for_each = toset(local.databases)

  database    = each.value
  role        = each.value
  schema      = "public"
  object_type = "table"
  privileges = toset([
    "INSERT",
    "DELETE",
    "REFERENCES",
    "SELECT",
    "TRIGGER",
    "TRUNCATE",
    "UPDATE",
  ])

  # Workaround to avoid terraform detecting unwanted changes that would cause downtime.
  # See: https://github.com/cyrilgdn/terraform-provider-postgresql/issues/197
  lifecycle {
    ignore_changes = [privileges]
  }
}

resource "postgresql_grant" "rw_self_sequence" {
  for_each = toset(local.databases)

  database    = each.value
  role        = each.value
  schema      = "public"
  object_type = "sequence"
  privileges = toset([
    "SELECT",
    "UPDATE",
    "USAGE",
  ])

  # Workaround to avoid terraform detecting unwanted changes that would cause downtime.
  # See: https://github.com/cyrilgdn/terraform-provider-postgresql/issues/197
  lifecycle {
    ignore_changes = [privileges]
  }
}

resource "postgresql_database" "databases" {
  for_each = toset(local.databases)

  name              = each.value
  owner             = postgresql_role.users[each.value].name
  template          = "template0"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  allow_connections = true
}

resource "aws_ssm_parameter" "connection_urls" {
  for_each = toset(local.databases)

  name  = "/prod/rds/shared/connection-urls/${each.value}"
  type  = "SecureString"
  value = "postgres://${each.value}:${random_password.users[each.value].result}@${aws_db_instance.shared.address}/${each.value}"
}

resource "aws_ssm_parameter" "connection_url_root" {
  name  = "/prod/rds/shared/connection-urls/root"
  type  = "SecureString"
  value = "postgres://root:${random_password.shared_root.result}@${aws_db_instance.shared.address}/postgres"
}
