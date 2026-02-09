# vpc-endpoints.tf - VPC Interface and Gateway Endpoints for private compute
#
# Interface Endpoints (required for SSM, CloudWatch, Secrets Manager):
#   ssm, ec2messages, ssmmessages, logs, secretsmanager, kms (optional)
#
# Gateway Endpoint:
#   s3 - Offline deps bucket, OS repos, agent downloads

# -----------------------------------------------------------------------------
# VPC Interface Endpoints Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "HTTPS from VPC CIDR for AWS API access"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr

  tags = {
    Name = "${local.name_prefix}-vpce-https-ingress"
  }
}

# -----------------------------------------------------------------------------
# VPC Interface Endpoints
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "interface" {
  for_each = local.vpc_endpoint_services_with_kms

  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-${each.key}"
  })
}

# -----------------------------------------------------------------------------
# S3 Gateway Endpoint
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = local.s3_endpoint_service
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-s3"
  })
}
