# =============================================================================
# LAB 3 — Transit Gateway (São Paulo Spoke)
# =============================================================================

# Explanation: Liberdade is São Paulo's Japanese town—local doctors, local compute, remote data.
resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider                        = aws.saopaulo
  description                     = "liberdade-tgw01 (Sao Paulo spoke)"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${local.name_prefix}-liberdade-tgw01"
  }
}

# Explanation: Liberdade accepts the corridor from Shinjuku—permissions are explicit, not assumed.
# Cross-state: shinjuku_to_liberdade_peer01 is created in the Tokyo state.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  count                         = var.shinjuku_peering_attachment_id != "" ? 1 : 0
  provider                      = aws.saopaulo
  transit_gateway_attachment_id = var.shinjuku_peering_attachment_id

  tags = {
    Name = "${local.name_prefix}-liberdade-accept-peer01"
  }
}

# Explanation: Liberdade attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  provider           = aws.saopaulo
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = aws_vpc.armageddon.id
  subnet_ids         = aws_subnet.private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-liberdade-attach-sp-vpc01"
  }
}

# =============================================================================
# LAB 3 — VPC Route Table Entries for Tokyo-Bound Traffic
# =============================================================================

# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_shinjuku_private_route01" {
  provider               = aws.saopaulo
  route_table_id         = aws_route_table.private_rt01.id
  destination_cidr_block = var.shinjuku_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}

# Explanation: VPC routes tell the VPC "send Tokyo traffic to the TGW."
# TGW routes tell the TGW "send Tokyo traffic across the peering link."
# Without this, traffic enters the TGW but has nowhere to go.
resource "aws_ec2_transit_gateway_route" "liberdade_to_shinjuku_tgw_route01" {
  count                          = var.shinjuku_peering_attachment_id != "" ? 1 : 0
  provider                       = aws.saopaulo
  destination_cidr_block         = var.shinjuku_vpc_cidr
  transit_gateway_attachment_id  = var.shinjuku_peering_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id
}