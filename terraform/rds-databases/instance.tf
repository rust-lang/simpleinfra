resource "random_password" "shared_root" {
  length           = 25
  special          = true
  override_special = "_%@"
}

resource "aws_db_subnet_group" "public" {
  name       = "public"
  subnet_ids = data.terraform_remote_state.shared.outputs.prod_vpc.public_subnets

  tags = {
    Name = "primary db subnet"
  }
}

# All of this security group stuff should go away once we migrate bastion to the
# prod vpc (vs. the legacy vpc).
data "aws_ssm_parameter" "allowed_ips" {
  for_each = toset(data.terraform_remote_state.shared.outputs.allowed_users)
  name     = "/prod/bastion/allowed-ips/${each.value}"
}

resource "aws_security_group" "rust_prod_db" {
  vpc_id      = data.terraform_remote_state.shared.outputs.prod_vpc.id
  name        = "rust-prod-database"
  description = "Access to the shared database from whitelisted networks"

  dynamic "ingress" {
    for_each = toset(data.terraform_remote_state.shared.outputs.allowed_users)
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [data.aws_ssm_parameter.allowed_ips[ingress.value].value]
      description = ingress.value
    }
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.shared.outputs.ecs_cluster_config.service_security_group_id]
    description     = "Connections from ECS"
  }

  tags = {
    Name = "rust-prod-database"
  }
}

resource "aws_db_instance" "shared" {
  allocated_storage            = 20
  max_allocated_storage        = 100
  backup_retention_period      = 3
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "12.2"
  instance_class               = "db.t3.micro"
  identifier                   = "shared"
  username                     = "root"
  password                     = random_password.shared_root.result
  db_subnet_group_name         = aws_db_subnet_group.public.name
  apply_immediately            = true
  final_snapshot_identifier    = "final-snapshot"
  deletion_protection          = true
  performance_insights_enabled = true
  allow_major_version_upgrade  = true

  # temporary, needed until bastion is in prod VPC and can be used for access
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rust_prod_db.id]
}
