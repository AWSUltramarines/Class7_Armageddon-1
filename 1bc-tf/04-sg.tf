# The Security Group for the VPC Endpoints (The "Door")
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Allow HTTPS from private subnets to AWS Services"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr] # Allow resources inside VPC to talk to endpoints
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# ================================================================ #

# 2. Updated EC2 Security Group (No SSH)
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Internal HTTP for testing 
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

# # OUTBOUND: Allow instance to talk to the Nat Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # OUTBOUND: Allow HTTPS to talk to the VPC Endpoints
  # egress {
  #   description = "HTTPS to VPC Endpoints"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = [var.cidr]
  # }

  tags = {
    Name = "ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }

}

# ================================================================ #

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS MySQL - allows access only from EC2 SG"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Inbound: MySQL from EC2 security group only (SG-to-SG reference)
resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_ec2" {
  security_group_id = aws_security_group.rds.id
  description       = "MySQL from EC2 security group"
  ip_protocol       = "tcp"
  from_port         = var.db_port
  to_port           = var.db_port

  # SG-to-SG reference - this is the critical security pattern
  referenced_security_group_id = aws_security_group.ec2.id

  tags = {
    Name = "rds-mysql-from-ec2"
  }
}