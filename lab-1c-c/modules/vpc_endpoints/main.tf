locals {
  services = {
    "ssm"            = "com.amazonaws.${var.region}.ssm"
    "ec2messages"    = "com.amazonaws.${var.region}.ec2messages"
    "ssmmessages"    = "com.amazonaws.${var.region}.ssmmessages"
    "logs"           = "com.amazonaws.${var.region}.logs"
    "secretsmanager" = "com.amazonaws.${var.region}.secretsmanager"
    "kms"            = "com.amazonaws.${var.region}.kms"
  }
}

###################################
####### VPC Endpoints
###################################
resource "aws_vpc_endpoint" "interface" {
  for_each = local.services

  vpc_id            = var.vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Interface"

  # Place endpoints in private subnets so private EC2s can reach them
  subnet_ids = var.private_subnet_ids[*]

  security_group_ids  = [var.vpce_sg_id]
  private_dns_enabled = true # Critical: Allows AWS DNS to resolve internal IPs

  tags = {
    Name = "${var.name_prefix}-endpoint-interface"
  }
}
# Gateway Endpoint (Specific for S3)
# S3 uses a Gateway, not an Interface endpoint (usually).
# It does NOT use Security Groups; it uses Route Tables.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  # Attach to the PRIVATE Route Table
  route_table_ids = [var.private_route_table]

  tags = {
    Name = "${var.name_prefix}-endpoint-s3"
  }
}
