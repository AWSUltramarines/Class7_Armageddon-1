resource "aws_db_instance" "rds-lab-mysql" {
  allocated_storage = 10
  db_name           = var.DB_NAME
  license_model     = "general-public-license" #o
  engine            = "mysql"
  engine_version    = "8.4"
  instance_class    = "db.t3.micro"
  manage_master_user_password = true
  username               = var.DB_USERNAME
  vpc_security_group_ids = [aws_security_group.rds-ec2-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db-mysql-subnet.name
  skip_final_snapshot    = true

    tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-lab"
    }
  )
}

