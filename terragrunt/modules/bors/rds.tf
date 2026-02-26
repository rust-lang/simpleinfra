resource "aws_db_instance" "primary" {
  db_name                 = "bors"
  engine                  = "postgres"
  engine_version          = "16.9"
  instance_class          = "db.t4g.micro"
  backup_retention_period = 7

  allow_major_version_upgrade = true

  # Make the instance accessible from outside the VPC.
  # This is needed because bastion is in the legacy AWS account.
  publicly_accessible = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  username = "bors"
  password = random_password.db.result

  allocated_storage = 30
  storage_type      = "gp3"
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_security_group" "rds" {
  name        = "rds"
  description = "Allow necessary communication for rds database"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "bastion" {
  security_group_id = aws_security_group.rds.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
  # Bastion is in the legacy AWS account, so we hardcode its IP address.
  cidr_ipv4   = "13.57.121.61/32"
  description = "Connections from the bastion"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ecs" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 0
  ip_protocol                  = "TCP"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_anywhere_v4" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_anywhere_v6" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}
