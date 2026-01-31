############################################
# Security Group for VPC Endpoints
############################################

resource "aws_security_group" "helga_vpce_sg01" {
  name        = "${local.name_prefix}-vpce-sg01"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.helga_vpc01.id

  ingress {
    description     = "HTTPS from EC2"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.helga_ec2_sg01.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-vpce-sg01"
  }
}

############################################
# VPC Interface Endpoints (SSM, Logs, Secrets)
############################################

# SSM endpoint (core Session Manager)
resource "aws_vpc_endpoint" "helga_vpce_ssm" {
  vpc_id              = aws_vpc.helga_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sg01.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

# EC2 Messages endpoint (Session Manager requirement)
resource "aws_vpc_endpoint" "helga_vpce_ec2messages" {
  vpc_id              = aws_vpc.helga_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sg01.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages"
  }
}

# SSM Messages endpoint (Session Manager requirement)
resource "aws_vpc_endpoint" "helga_vpce_ssmmessages" {
  vpc_id              = aws_vpc.helga_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sg01.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages"
  }
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "helga_vpce_logs" {
  vpc_id              = aws_vpc.helga_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sg01.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

# Secrets Manager endpoint
resource "aws_vpc_endpoint" "helga_vpce_secretsmanager" {
  vpc_id              = aws_vpc.helga_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sg01.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-secretsmanager"
  }
}
############################################
# S3 Gateway Endpoint
############################################

resource "aws_vpc_endpoint" "helga_vpce_s3" {
  vpc_id            = aws_vpc.helga_vpc01.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [
    aws_route_table.helga_private_rt01.id,
    aws_route_table.helga_public_rt01.id
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}

resource "aws_instance" "helga_ec201" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  
  # CHANGED: Move to private subnet
  subnet_id              = aws_subnet.helga_private_subnets[0].id
  
  vpc_security_group_ids = [aws_security_group.helga_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.helga_instance_profile01.name
  user_data              = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}