###################################
####### VPC
###################################
resource "aws_vpc" "dev" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name      = "${var.name_prefix}-vpc"
    Terraform = var.terraform_tag
  }
}
###################################
####### Subnets
###################################
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id     = aws_vpc.dev.id
  cidr_block = var.public_subnet_cidrs[count.index]

  # Using element() we will loop back to the first AZ if we have more subnets than AZs
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.name_prefix}-public-subnets"
    Terraform = var.terraform_tag
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id     = aws_vpc.dev.id
  cidr_block = var.private_subnet_cidrs[count.index]

  # Using element() we will loop back tot he first AZ if we have more subnets than AZs
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.name_prefix}-private-subnets"
    Terraform = var.terraform_tag
  }
}
############################################
# RDS Subnet Group
############################################
resource "aws_db_subnet_group" "default" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name      = "${var.name_prefix}-db-subnet-group"
    Terraform = var.terraform_tag
  }
}

###################################
####### Gateway
###################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name      = "${var.name_prefix}-igw"
    Terraform = var.terraform_tag
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[1].id # NAT in a public subnet

  tags = {
    Name = "${var.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

###################################
####### Route Tables
###################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Private route table - no internet route (isolated)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

# ROUTE: Send non-local traffic from Private Subnets to NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
###################################
####### Security Groups
###################################
######### Compute Security Group
resource "aws_security_group" "compute_sg" {
  name        = "${var.name_prefix}-compute-sg"
  description = "EC2 Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${var.name_prefix}-compute-sg"
    Terraform = var.terraform_tag
  }
}
resource "aws_vpc_security_group_ingress_rule" "compute_to_alb" {
  security_group_id            = aws_security_group.compute_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "compute_to_alb" {
  security_group_id = aws_security_group.compute_sg.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}
######## ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${var.name_prefix}-alb-sg"
    Terraform = var.terraform_tag
  }
}
resource "aws_vpc_security_group_ingress_rule" "alb_http_rules" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4         = var.generic_inbound_cidr_ipv4
}
resource "aws_vpc_security_group_ingress_rule" "alb_https_rules" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  cidr_ipv4         = var.generic_inbound_cidr_ipv4
}
resource "aws_vpc_security_group_egress_rule" "alb_egress_rules" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}
######### VPC Endpoint Security Group
resource "aws_security_group" "vpce_sg" {
  name        = "${var.name_prefix}-vpce-sg"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name = "${var.name_prefix}-vpce-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.vpce_sg.id
  cidr_ipv4         = var.vpce_https_cidr_ipv4
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "vpce_egress_rules" {
  security_group_id = aws_security_group.vpce_sg.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}
######### RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${var.name_prefix}-rds-sg"
    Terraform = var.terraform_tag
  }
}
######## Compute to RDS Security Group
resource "aws_vpc_security_group_ingress_rule" "compute_to_rds" {
  security_group_id            = aws_security_group.rds_sg.id
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


