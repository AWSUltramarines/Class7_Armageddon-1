resource "aws_db_instance" "lab-mysql" {
  allocated_storage    = 20
  db_name              = "labmysql"
  identifier           = "labmysql"
  engine               = "mysql"
  engine_version       = "8.0.43"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "armageddon1"
  vpc_security_group_ids = [aws_security_group.rds-lab.id]
  parameter_group_name = "default.mysql8.0"
  storage_type         = "gp2"
  performance_insights_enabled = false
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible  = false
  port                 = 3306 
  backup_retention_period = 1
  storage_encrypted    = true
  skip_final_snapshot  = true
  auto_minor_version_upgrade = true
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.private_a.id,
  aws_subnet.private_b.id,
  aws_subnet.private_c.id]
}

