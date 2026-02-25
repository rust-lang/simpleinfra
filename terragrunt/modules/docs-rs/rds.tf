locals {
  docs_rs_username = "docsrs"
  docs_rs_db_name  = "docsrs"
}

resource "random_password" "db" {
  length  = 64
  special = false
}

resource "aws_db_subnet_group" "db" {
  name       = "docs-rs-db"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "db" {
  vpc_id      = var.cluster_config.vpc_id
  name        = "docs-rs-db"
  description = "Access to the docs.rs database"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Connections from web servers on ECS, bastion, and builder"
    security_groups = [aws_security_group.web.id, var.bastion_security_group_id, aws_security_group.builder.id]
  }
}

resource "aws_db_instance" "db" {
  identifier = "docs-rs"

  engine         = "postgres"
  engine_version = "18"

  # 2 vCPUs, 2 GiB RAM.
  instance_class = "db.t4g.small"
  # General Purpose SSD storage. RDS default.
  storage_type         = "gp3"
  db_subnet_group_name = aws_db_subnet_group.db.name
  # The allocated storage in GiB.
  allocated_storage = 20
  # Storage autoscaling.
  max_allocated_storage = 100

  # Allow connections from aws resources in the same VPC, such as ECS, EC2 and bastion.
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db.id]

  db_name  = local.docs_rs_db_name
  username = local.docs_rs_username
  password = random_password.db.result

  # Retain backups for 30 days
  backup_retention_period = 30
  # Daily time range (in UTC) during which automated backups are created
  backup_window = "05:00-06:00"

  # Prevent deleting the DB
  deletion_protection = true
  # Don't delete automated backups when deleting the DB,
  # to allow restoring to a point in time after deletion if needed.
  delete_automated_backups = false

  # Disable automatic updates like `18.2 -> 19.0`.
  allow_major_version_upgrade = false
  # Enable automatic updates like `18.2 -> 18.3`.
  auto_minor_version_upgrade = true

  # Set the maintainance window to a time where we expect low traffic and the
  # Infrastructure team and Docs-rs team are available to intervene if something goes wrong.
  # The DB is unavailable during this time only if the system changes that require downtime
  # (such as a change in DB instance class) are being applied.
  # The DB is unavailable only for the minimum amount of time required to make the necessary changes.
  maintenance_window = "Mon:09:00-Mon:10:00" # UTC

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "aws_ssm_parameter" "connection_url" {
  name  = "/docs-rs/database-url"
  type  = "SecureString"
  value = "postgres://${local.docs_rs_username}:${random_password.db.result}@${aws_db_instance.db.address}/${local.docs_rs_db_name}"
}
