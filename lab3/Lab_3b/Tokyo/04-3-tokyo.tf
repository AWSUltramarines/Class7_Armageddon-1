############################################
# LAB 3A: TOKYO TRANSIT GATEWAY (HUB)
# Shinjuku Station - Data corridor hub
# Builds on: helga_vpc01, helga_private_subnets
############################################

resource "aws_ec2_transit_gateway" "shinjuku_tgwlab3" {
  count       = var.enable_tgw ? 1 : 0
  description = "shinjuku-tgw01 (Tokyo hub for APPI-compliant architecture)"
  
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name    = "shinjuku-tgwlab3"
    Role    = "Hub"
    Project = var.project_name
  }
}

############################################
# TOKYO VPC ATTACHMENT TO TGW
# Connects to your existing helga_vpc01 (10.241.0.0/16)
# Attaches to PRIVATE subnets only:
#   - 10.241.101.0/24 (private-1)
#   - 10.241.102.0/24 (private-2)
############################################

resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpclab3" {
  count              = var.enable_tgw ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id
  
  # References YOUR Lab 2 VPC (10.241.0.0/16)
  vpc_id = aws_vpc.helga_vpclab3.id
  
  # Attach to PRIVATE subnets only - TGW traffic stays internal
  subnet_ids = [
    aws_subnet.helga_private_subnets[0].id,
    aws_subnet.helga_private_subnets[1].id
  ]

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name    = "shinjuku-attach-tokyo-vpclab3"
    Project = var.project_name
  }
}

############################################
# TGW PEERING ATTACHMENT (Tokyo → São Paulo)
# Shinjuku opens corridor to Liberdade
# Tokyo (10.241.0.0/16) ↔ São Paulo (10.214.0.0/16)
############################################

resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  count                   = var.enable_tgw && var.saopaulo_tgw_id != "" ? 1 : 0
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.saopaulo_tgw_id
  #peer_transit_gateway_id = data.aws_ec2_transit_gateway.saopaulo_tgw.id
 
  tags = {
    Name = "shinjuku-to-liberdade-peer01"
    Type = "Cross-Region-Peering"
  }
}

############################################
# TGW ROUTE TABLE ENTRY FOR PEERING
# Route to São Paulo CIDR (10.214.0.0/16)
############################################

 resource "aws_ec2_transit_gateway_route" "shinjuku_route_to_liberdade" {
  count                          = var.enable_tgw && var.saopaulo_tgw_id != "" ? 1 : 0
  destination_cidr_block         = var.saopaulo_vpc_cidr  # 10.214.0.0/16
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].association_default_route_table_id

  depends_on = [aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01]
  } 

############################################
# TOKYO RETURN ROUTES TO SÃO PAULO
# Adds route in helga_private_rtlab3
# Destination: 10.214.0.0/16 → TGW
############################################

resource "aws_route" "shinjuku_to_sp_route01" {
  count = var.enable_tgw ? 1 : 0
  
  # References YOUR Lab 1C route table
  route_table_id         = aws_route_table.helga_private_rtlab3.id
  destination_cidr_block = var.saopaulo_vpc_cidr  # 10.214.0.0/16
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id
}

############################################
# RDS SECURITY GROUP RULE FOR SÃO PAULO
# Allows São Paulo compute (10.214.0.0/16) to access helga_rdslab3
############################################

/* resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  count = var.enable_tgw ? 1 : 0
  
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.saopaulo_vpc_cidr]  # 10.214.0.0/16
  description       = "MySQL from Sao Paulo VPC via TGW"
  
  # References YOUR Lab 1C RDS security group
  security_group_id = aws_security_group.helga_rds_sglab3.id
} */

