# Security Group for VPC Endpoints (allows HTTPS from the VPC)
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Allow TLS inbound from VPC for Endpoints"
  vpc_id      = aws_vpc.armageddon-VPC.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.armageddon-VPC.cidr_block]
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each          = toset(local.services)
  vpc_id            = aws_vpc.armageddon-VPC.id
  service_name      = "com.amazonaws.us-east-1.${each.value}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = [aws_subnet.private-us-east-1a.id, aws_subnet.private-us-east-1b.id]
  
  private_dns_enabled = true
}

# S3 Gateway Endpoint (Free and highly recommended)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.armageddon-VPC.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

# Fetch the S3 service name for your current region automatically
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = aws_vpc.armageddon-VPC.id
  service_name = data.aws_vpc_endpoint_service.s3.service_name
  
# This explicitly defines it as a Gateway endpoint
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "s3-gateway-endpoint"
  }
}