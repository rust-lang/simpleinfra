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
resource "aws_db_instance" "primary" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.5"
  instance_class       = "db.t3.micro"
  username             = "root"
  password             = random_password.database.result
  db_subnet_group_name = aws_db_subnet_group.public.name
}
