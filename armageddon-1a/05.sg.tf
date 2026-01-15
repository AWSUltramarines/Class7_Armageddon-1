resource "aws_security_group" "compute_sg" {
  name        = "${local.name_prefix}-${var.sg_name}"
  description = "EC2 Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${local.name_prefix}-compute-sg"
    Terraform = local.terraform_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.compute_sg.id
  cidr_ipv4         = var.sg_ssh_cidr_ipv4
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.compute_sg.id
  cidr_ipv4         = var.sg_http_cidr_ipv4
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
  security_group_id = aws_security_group.compute_sg.id
  cidr_ipv4         = var.sg_icmp_cidr_ipv4
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "compute_egress_rules" {
  security_group_id = aws_security_group.compute_sg.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}

# ###########################################
# RDS Security Group
###########################################

resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-${var.rds_sg_name}"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${local.name_prefix}-rds-sg"
    Terraform = local.terraform_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "compute_to_rds" {
  security_group_id = aws_security_group.rds_sg.id
  # cidr_ipv4                    = var.rds_sg_cidr_ipv4
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.compute_sg.id
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_rules" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}