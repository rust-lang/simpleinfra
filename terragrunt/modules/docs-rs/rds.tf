# resource "random_password" "db" {
#   length  = 64
#   special = false
# }
#
# resource "aws_db_subnet_group" "db" {
#   name       = "docs-rs-db"
#   subnet_ids = var.private_subnet_ids
# }
#
# resource "aws_security_group" "db" {
#   vpc_id      = var.cluster_config.vpc_id
#   name        = "docs-rs-db"
#   description = "Access to the docs.rs database"
#
#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     description     = "Connections from the docs.rs web servers on ECS"
#     security_groups = [aws_security_group.web.id]
#   }
#
#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     description     = "Connections from the bastion"
#     security_groups = [var.bastion_security_group_id]
#   }
# }
#
# resource "aws_db_instance" "db" {
#   identifier = "docs-rs"
#
#   engine         = "postgres"
#   engine_version = "14.3"
#
#   instance_class        = "db.t4g.small"
#   storage_type          = "gp2"
#   db_subnet_group_name  = aws_db_subnet_group.db.name
#   allocated_storage     = 20
#   max_allocated_storage = 100
#
#   publicly_accessible    = false
#   vpc_security_group_ids = [aws_security_group.db.id]
#
#   db_name  = "docsrs"
#   username = "docsrs"
#   password = random_password.db.result
#
#   backup_retention_period = 30
#   backup_window           = "05:00-06:00" # UTC
#
#   deletion_protection      = true
#   delete_automated_backups = false
#
#   allow_major_version_upgrade = false
#   auto_minor_version_upgrade  = true
#   maintenance_window          = "Tue:15:00-Tue:16:00" # UTC
#
#   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
#   performance_insights_enabled    = true
#
#   lifecycle {
#     ignore_changes = [
#       engine_version,
#     ]
#   }
# }
#
# resource "aws_ssm_parameter" "connection_url" {
#   name  = "/docs-rs/database-url"
#   type  = "SecureString"
#   value = "postgres://docsrs:${random_password.db.result}@${aws_db_instance.db.address}/docsrs"
# }
