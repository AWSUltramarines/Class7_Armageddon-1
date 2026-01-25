############################################
# RDS Database Instance
############################################
resource "aws_db_instance" "rds_instance" {
  identifier = var.db_name

  username = var.db_username
  password = var.db_password

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  parameter_group_name = var.parameter_group_name
  storage_encrypted    = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_sg_id]

  skip_final_snapshot = var.skip_final_snapshot
  publicly_accessible = var.publicly_accessible

  # Disabled for free tier
  performance_insights_enabled = false

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name      = "${var.db_prefix}-rds-instance"
    Terraform = var.terraform_tag
  }

}
