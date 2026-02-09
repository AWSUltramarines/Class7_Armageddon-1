# security_groups.tf - Security groups for ALB, EC2, and RDS
#
# Lab 1c Security Model:
#   airgap:     EC2 SG (no ALB ingress, HTTPS to endpoints, MySQL to RDS, S3)
#   public_alb: ALB SG + EC2 SG (HTTP from ALB) + RDS SG
#
# No SSH in either mode - use Session Manager

# -----------------------------------------------------------------------------
# ALB Security Group (public_alb mode only)
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  count = local.is_airgap ? 0 : 1

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Inbound: HTTP from allowed CIDRs (public_alb mode only)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = local.is_airgap ? toset([]) : toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value

  tags = {
    Name = "${local.name_prefix}-alb-http-${replace(each.value, "/", "-")}"
  }
}

# ALB Outbound: HTTP to EC2 security group only (public_alb mode only)
resource "aws_vpc_security_group_egress_rule" "alb_to_ec2" {
  count = local.is_airgap ? 0 : 1

  security_group_id            = aws_security_group.alb[0].id
  description                  = "HTTP to EC2 instances"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.ec2.id

  tags = {
    Name = "${local.name_prefix}-alb-to-ec2"
  }
}

# -----------------------------------------------------------------------------
# EC2 Security Group (always created)
# -----------------------------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for EC2 web application instance (private)"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Inbound: HTTP from ALB security group ONLY (public_alb mode only)
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  count = local.is_airgap ? 0 : 1

  security_group_id            = aws_security_group.ec2.id
  description                  = "HTTP from ALB security group only"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb[0].id

  tags = {
    Name = "${local.name_prefix}-ec2-http-from-alb"
  }
}

# EC2 Outbound: HTTPS to VPC endpoints (for AWS APIs)
resource "aws_vpc_security_group_egress_rule" "ec2_https_to_endpoints" {
  security_group_id            = aws_security_group.ec2.id
  description                  = "HTTPS to VPC endpoints for AWS API access"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id

  tags = {
    Name = "${local.name_prefix}-ec2-to-endpoints"
  }
}

# EC2 Outbound: MySQL to RDS
resource "aws_vpc_security_group_egress_rule" "ec2_mysql_to_rds" {
  security_group_id            = aws_security_group.ec2.id
  description                  = "MySQL to RDS"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.rds.id

  tags = {
    Name = "${local.name_prefix}-ec2-to-rds"
  }
}

# EC2 Outbound: S3 via Gateway Endpoint (uses S3 prefix list)
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_security_group_egress_rule" "ec2_to_s3" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTPS to S3 via Gateway Endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id

  tags = {
    Name = "${local.name_prefix}-ec2-to-s3"
  }
}

# -----------------------------------------------------------------------------
# RDS Security Group (always created)
# -----------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS MySQL - allows access only from EC2 SG"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from EC2 security group"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.ec2.id

  tags = {
    Name = "${local.name_prefix}-rds-mysql-from-ec2"
  }
}
