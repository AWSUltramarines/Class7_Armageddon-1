resource "aws_db_instance" "rds_instance" {
  identifier = var.db_name

  username = var.db_username
  password = var.db_password

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  parameter_group_name = var.parameter_group_name

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  #   manage_master_user_password = true
  skip_final_snapshot = var.skip_final_snapshot
  publicly_accessible = var.publicly_accessible

  tags = {
    Name      = "${local.db_prefix}-rds-instance"
    Terraform = local.terraform_tag
  }

}

resource "aws_db_subnet_group" "default" {
  name       = "${local.name_prefix}-rds-subnet-group"
  subnet_ids = values(local.private_subnets)[*].id

  tags = {
    Name      = "${local.name_prefix}-db-subnet-group"
    Terraform = local.terraform_tag
  }
}
