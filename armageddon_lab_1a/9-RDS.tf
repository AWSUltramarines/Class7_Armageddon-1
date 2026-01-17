resource "aws_db_instance" "lab-mysql" {
  allocated_storage    = 20
  db_name              = "labdb"
  identifier           = "labdb"
  engine               = "mysql"
  engine_version       = "8.0.43"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "armageddon123!"
  vpc_security_group_ids = [aws_security_group.sg-rds-lab.id]
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
  subnet_ids = [aws_subnet.private-us-east-1a.id,
  aws_subnet.private-us-east-1b.id,
  aws_subnet.private-us-east-1c.id]
}

# # resource "aws_kms_key" "default" {
# #   description = "Encryption key for automated backups"

# #   provider = aws.replica
# # }

# # resource "aws_db_instance_automated_backups_replication" "default" {
# #   source_db_instance_arn = aws_db_instance.labdb.arn
# #   kms_key_id             = aws_kms_key.default.arn

# #   provider = aws.replica
# # }