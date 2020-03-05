locals {
  databases = [
    "triagebot",
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
  value = "postgres://${each.value}:${random_password.users[each.value].result}@${aws_db_instance.primary.address}/${each.value}"
}
