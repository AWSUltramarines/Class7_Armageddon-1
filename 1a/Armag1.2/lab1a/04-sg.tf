# CREATE the RDS Security Group (This is fine to keep)
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS MySQL"
  
  # FIX: Point to the EXISTING VPC data source
  vpc_id      = data.aws_vpc.armag1.id

  tags = {
    Name = "rds_sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress Rule to trust the existing EC2 Security Group
resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_ec2" {
  security_group_id = aws_security_group.rds.id
  description       = "MySQL from existing EC2 security group"
  ip_protocol       = "tcp"
  from_port         = var.db_port
  to_port           = var.db_port

  # Trust the existing EC2 Security Group (using data), not a new one
  referenced_security_group_id = data.aws_security_group.app_sg.id 

  tags = {
    Name = "rds-mysql-from-ec2"
  }
}