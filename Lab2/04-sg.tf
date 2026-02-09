############################################
# Security Group for VPC Endpoints
############################################

resource "aws_security_group" "helga_vpce_sglab2a" {
  name        = "${local.name_prefix}-vpce-sglab2a"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.helga_vpclab2a.id

  ingress {
    description     = "HTTPS from EC2"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.helga_ec2_sglab2a.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-vpce-sglab2a"
  }
}

############################################
# VPC Interface Endpoints (SSM, Logs, Secrets)
############################################

# SSM endpoint (core Session Manager)
resource "aws_vpc_endpoint" "helga_vpce_ssm" {
  vpc_id              = aws_vpc.helga_vpclab2a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sglab2a.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

# EC2 Messages endpoint (Session Manager requirement)
resource "aws_vpc_endpoint" "helga_vpce_ec2messages" {
  vpc_id              = aws_vpc.helga_vpclab2a.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sglab2a.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages"
  }
}

# SSM Messages endpoint (Session Manager requirement)
resource "aws_vpc_endpoint" "helga_vpce_ssmmessages" {
  vpc_id              = aws_vpc.helga_vpclab2a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sglab2a.id]
  private_dns_enabled = true
  region              = "us-east-1"

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages"
  }
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "helga_vpce_logs" {
  vpc_id              = aws_vpc.helga_vpclab2a.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sglab2a.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

# Secrets Manager endpoint
resource "aws_vpc_endpoint" "helga_vpce_secretsmanager" {
  vpc_id              = aws_vpc.helga_vpclab2a.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.helga_private_subnets[*].id
  security_group_ids  = [aws_security_group.helga_vpce_sglab2a.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-secretsmanager"
  }
}
############################################
# S3 Gateway Endpoint
############################################

resource "aws_vpc_endpoint" "helga_vpce_s3" {
  vpc_id            = aws_vpc.helga_vpclab2a.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [
    aws_route_table.helga_private_rtlab2a.id,
    aws_route_table.helga_public_rtlab2a.id
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}

resource "aws_instance" "helga_ec2lab2a" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  
  # CHANGED: Move to private subnet
  subnet_id              = aws_subnet.helga_private_subnets[0].id
  
  vpc_security_group_ids = [aws_security_group.helga_ec2_sglab2a.id]
  iam_instance_profile   = aws_iam_instance_profile.helga_instance_profilelab2a.name
  user_data = templatefile("./scripts/user_data.sh", {
        secret_name = data.aws_secretsmanager_secret.helga_db_secretlab2a.id
    })


  

  tags = {
    Name = "${local.name_prefix}-ec2lab2a"
  }
}