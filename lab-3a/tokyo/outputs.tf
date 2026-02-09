############################################
# Lab 3A: Tokyo Outputs
# Sao Paulo consumes these to configure
# routes, SG rules, and app connectivity
############################################

output "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR block"
  value       = var.cidr_block
}

output "tokyo_tgw_id" {
  description = "Tokyo Transit Gateway ID (for Sao Paulo peering)"
  value       = var.enable_tgw ? aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id : null
}

output "tokyo_rds_endpoint" {
  description = "Tokyo RDS endpoint (Sao Paulo EC2 connects here via TGW)"
  value       = module.database.rds_connection.endpoint
}

output "tokyo_vpc_id" {
  description = "Tokyo VPC ID"
  value       = module.network.vpc_id
}

# output "tokyo_tgw_peering_attachment_id" {
#   description = "TGW peering attachment ID (Tokyo to Sao Paulo)"
#   value       = var.enable_tgw && var.saopaulo_tgw_id != "" ? aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01[0].id : null
# }

output "alb_dns_name" {
  description = "Tokyo ALB DNS name"
  value       = module.load_balancer.alb_dns_name
}
