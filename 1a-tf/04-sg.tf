resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 web application instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Inbound: HTTP from allowed CIDRs
resource "aws_vpc_security_group_ingress_rule" "ec2_http" {

  # 'toset' converts and packages your list variable into a format that 'for_each' can accept.
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.ec2.id
  description       = "HTTP from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value

  tags = {
    Name = "ec2-http-${replace(each.value, "/", "-")}"
  }
}

# EC2 Inbound: SSH from restricted CIDR (conditional)
# The ? means if/else. If True return 1, else return 0
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  count = var.ssh_allowed_cidr != "" ? 1 : 0

  security_group_id = aws_security_group.ec2.id
  description       = "SSH from ${var.ssh_allowed_cidr}"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr

  tags = {
    Name = "ec2-ssh"
  }
}

# EC2 Outbound: All traffic (required for package installation and AWS API calls)
resource "aws_vpc_security_group_egress_rule" "ec2_all_outbound" {
  security_group_id = aws_security_group.ec2.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "ec2-outbound"
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