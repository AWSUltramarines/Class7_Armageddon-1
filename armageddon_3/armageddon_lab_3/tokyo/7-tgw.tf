# =============================================================================
# LAB 3 — Transit Gateway (Tokyo Hub)
# =============================================================================

# Explanation: Shinjuku Station is the hub—Tokyo is the data authority.
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description                     = "shinjuku-tgw01 (Tokyo hub)"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${local.name_prefix}-shinjuku-tgw01"
  }
}

# Explanation: Shinjuku connects to the Tokyo VPC—this is the gate to the medical records vault.
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = aws_vpc.armageddon.id
  subnet_ids         = aws_subnet.private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-shinjuku-attach-tokyo-vpc01"
  }
}

# Explanation: Shinjuku opens a corridor request to Liberdade—compute may travel, data may not.
# Cross-state: liberdade_tgw01 is created in the São Paulo state.
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw01.id
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.liberdade_tgw_id

  tags = {
    Name = "${local.name_prefix}-shinjuku-to-liberdade-peer01"
  }
}

# =============================================================================
# LAB 3 — VPC Route Table Entries for São Paulo Return Traffic
# =============================================================================

# Explanation: Shinjuku returns traffic to Liberdade—because doctors need answers, not one-way tunnels.
resource "aws_route" "shinjuku_to_liberdade_private_route01" {
  route_table_id         = aws_route_table.private_rt01.id
  destination_cidr_block = var.liberdade_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

# Explanation: VPC routes tell the VPC "send São Paulo traffic to the TGW."
# TGW routes tell the TGW "send São Paulo traffic across the peering link."
# Without this, return traffic enters the TGW but has nowhere to go.
resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade_tgw_route01" {
  destination_cidr_block         = var.liberdade_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.association_default_route_table_id
}
