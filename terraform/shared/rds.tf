resource "random_password" "database" {
  length           = 25
  special          = true
  override_special = "_%@"
}

resource "aws_db_subnet_group" "public" {
  name       = "public"
  subnet_ids = module.vpc_prod.public_subnets

  tags = {
    Name = "primary db subnet"
  }
}

# All of this security group stuff should go away once we migrate bastion to the
# prod vpc (vs. the legacy vpc).
data "aws_ssm_parameter" "allowed_ips" {
  for_each = toset(local.allowed_users)
  name     = "/prod/bastion/allowed-ips/${each.value}"
}

resource "aws_security_group" "rust_prod_db" {
  vpc_id      = module.vpc_prod.id
  name        = "rust-prod-database"
  description = "Access to the shared database from whitelisted networks"

  dynamic "ingress" {
    for_each = toset(local.allowed_users)
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
    security_groups = [module.service_ecs_cluster.config.service_security_group_id]
    description     = "Connections from ECS"
  }

  tags = {
    Name = "rust-prod-database"
  }
}

resource "aws_db_instance" "primary" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.5"
  instance_class       = "db.t3.micro"
  identifier           = "shared"
  username             = "root"
  password             = random_password.database.result
  db_subnet_group_name = aws_db_subnet_group.public.name
  apply_immediately    = true

  # temporary, needed until bastion is in prod VPC and can be used for access
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rust_prod_db.id]
  skip_final_snapshot    = true
}

provider "postgresql" {
  host            = aws_db_instance.primary.address
  port            = aws_db_instance.primary.port
  database        = "postgres"
  username        = aws_db_instance.primary.username
  password        = aws_db_instance.primary.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}
