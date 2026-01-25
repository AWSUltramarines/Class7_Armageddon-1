############################################
# VPC Endpoint - S3 (Gateway)
############################################
resource "aws_vpc_endpoint" "vpce_s3_gw" {
  vpc_id            = aws_vpc.dev.id
  service_name      = "com.amazonaws.${data.aws_region.region.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3-gw"
  }
}

############################################
# VPC Endpoints - SSM (Interface)
############################################
resource "aws_vpc_endpoint" "vpce_ssm" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "vpce_ec2messages" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages"
  }
}

resource "aws_vpc_endpoint" "vpce_ssmmessages" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages"
  }
}

############################################
# VPC Endpoint - CloudWatch Logs (Interface)
############################################
resource "aws_vpc_endpoint" "vpce_logs" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

############################################
# VPC Endpoint - Secrets Manager (Interface)
############################################
resource "aws_vpc_endpoint" "vpce_secrets" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-secrets"
  }
}

############################################
# Optional: VPC Endpoint - KMS (Interface)
############################################
resource "aws_vpc_endpoint" "vpce_kms" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-kms"
  }
}

############################################
# Optional: VPC Endpoint - EC2 
############################################
resource "aws_vpc_endpoint" "vpce_ec2" {
  vpc_id              = aws_vpc.dev.id
  service_name        = "com.amazonaws.${data.aws_region.region.name}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ec2"
  }
}

