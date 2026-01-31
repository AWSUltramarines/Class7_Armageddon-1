output "saopaulo_vpc_id" {
  description = "São Paulo VPC ID"
  value       = aws_vpc.liberdade_vpclab3.id
}

output "saopaulo_vpc_cidr" {
  description = "São Paulo VPC CIDR"
  value       = aws_vpc.liberdade_vpclab3.cidr_block
}

output "saopaulo_public_subnet_ids" {
  description = "São Paulo public subnet IDs"
  value       = aws_subnet.liberdade_public_subnets[*].id
}

output "saopaulo_private_subnet_ids" {
  description = "São Paulo private subnet IDs"
  value       = aws_subnet.liberdade_private_subnets[*].id
}

output "saopaulo_tgw_id" {
  description = "São Paulo Transit Gateway ID (for Tokyo peering)"
  value       = var.enable_tgw ? aws_ec2_transit_gateway.liberdade_tgwlab3[0].id : null
}

output "saopaulo_tgw_arn" {
  description = "São Paulo Transit Gateway ARN"
  value       = var.enable_tgw ? aws_ec2_transit_gateway.liberdade_tgwlab3[0].arn : null
}

output "saopaulo_peering_accepter_id" {
  description = "Sao Paulo peering accepter attachment ID"
  value       = var.enable_tgw && var.tokyo_tgw_id != "" ? aws_ec2_transit_gateway_peering_attachment_accepter.accept_tokyo_peer01[0].id : null
}

output "saopaulo_tgw_route_to_tokyo" {
  description = "TGW route to Tokyo CIDR"
  value       = var.enable_tgw && var.tokyo_tgw_id != "" ? aws_ec2_transit_gateway_route.liberdade_route_to_tokyo[0].destination_cidr_block : null
}