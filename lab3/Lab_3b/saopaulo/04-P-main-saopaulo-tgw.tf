resource "aws_ec2_transit_gateway" "liberdade_tgwlab3" {
  count       = var.enable_tgw ? 1 : 0
  description = "liberdade-tgwlab3 (Sao Paulo spoke)"
  
  amazon_side_asn                 = 64513
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name    = "liberdade-tgwlab3"
    Role    = "Spoke"
    Project = var.project_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpclab3" {
  count              = var.enable_tgw ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgwlab3[0].id
  vpc_id             = aws_vpc.liberdade_vpclab3.id
  
  subnet_ids = [
    aws_subnet.liberdade_private_subnets[0].id,
    aws_subnet.liberdade_private_subnets[1].id
  ]

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name    = "liberdade-attach-sp-vpclab3"
    Project = var.project_name
  }
}

############################################
# ACCEPT TGW PEERING FROM TOKYO
# Liberdade accepts corridor from Shinjuku
############################################

data "aws_ec2_transit_gateway_peering_attachment" "from_tokyo" {
  count = var.enable_tgw && var.tokyo_tgw_id != "" ? 1 : 0
  #count = var.enable_tgw && data.aws_ec2_transit_gateway.tokyo_tgw.id != "" ? 1 : 0

  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.liberdade_tgwlab3[0].id]
  }

  filter {
    name   = "state"
    values = ["pendingAcceptance", "available"]
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_tokyo_peer01" {
  count = var.enable_tgw && var.tokyo_tgw_id != "" ? 1 : 0
  #count = var.enable_tgw && data.aws_ec2_transit_gateway.tokyo_tgw.id != "" ? 1 : 0

  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.from_tokyo[0].id

  tags = {
    Name    = "liberdade-accept-tokyo-peer01"
    Type    = "Cross-Region-Peering"
    Project = var.project_name
  }
}

############################################
# TGW ROUTE TO TOKYO
# Route Tokyo CIDR (10.241.0.0/16) via peering
############################################

resource "aws_ec2_transit_gateway_route" "liberdade_route_to_tokyo" {
  count = var.enable_tgw && var.tokyo_tgw_id != "" ? 1 : 0
  #count = var.enable_tgw && data.aws_ec2_transit_gateway.tokyo_tgw.id != "" ? 1 : 0

  destination_cidr_block         = var.tokyo_vpc_cidr  # 10.241.0.0/16
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.accept_tokyo_peer01[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgwlab3[0].association_default_route_table_id

  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_tokyo_peer01]
}

############################################
# SÃO PAULO VPC ROUTES TO TOKYO
# Liberdade private subnets → Tokyo for RDS access
# Destination: 10.241.0.0/16 (Tokyo VPC) → TGW
############################################

resource "aws_route" "liberdade_to_tokyo_route01" {
  count = var.enable_tgw ? 1 : 0

  route_table_id         = aws_route_table.liberdade_private_rtlab3.id
  destination_cidr_block = var.tokyo_vpc_cidr  # 10.241.0.0/16
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgwlab3[0].id
}

############################################
# SÃO PAULO EC2 SECURITY GROUP
# Allows outbound to Tokyo RDS (10.241.0.0/16)
############################################

resource "aws_security_group" "liberdade_ec2_sglab3" {
  count = var.enable_tgw ? 1 : 0

  name        = "${var.project_name}-ec2-sglab3"
  description = "Sao Paulo EC2 - connects to Tokyo RDS via TGW"
  vpc_id      = aws_vpc.liberdade_vpclab3.id

  # Outbound to Tokyo RDS
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.tokyo_vpc_cidr]  # 10.241.0.0/16
    description = "MySQL to Tokyo RDS via TGW"
  }

  # General outbound (for updates, SSM, etc.)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  tags = {
    Name    = "${var.project_name}-ec2-sglab3"
    Project = var.project_name
  }
}