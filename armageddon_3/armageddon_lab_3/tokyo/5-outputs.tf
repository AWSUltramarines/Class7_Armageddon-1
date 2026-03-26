# Explanation: Outputs are your mission report—what got built and where to find it.
output "vpc_id" {
  value = aws_vpc.armageddon.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "ec2_instance_id" {
  value = aws_instance.lab-ec201.id
}

output "rds_endpoint" {
  value = aws_db_instance.rds01.address
}

output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic01.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log_group01.name
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.lab-ec201.private_ip
}

output "ssm_session_command" {
  description = "AWS CLI command to start SSM session"
  value       = "aws ssm start-session --target ${aws_instance.lab-ec201.id}"
}

#--------------BONUS A OUTPUTS------------------
output "vpce_ssm_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "vpce_logs_id" {
  value = aws_vpc_endpoint.logs.id
}

output "vpce_secrets_id" {
  value = aws_vpc_endpoint.secretsmanager.id
}

output "vpce_s3_id" {
  value = aws_vpc_endpoint.s3.id
}

#-----------------BONUS B OUTPUTS---------------------

output "alb_dns_name" {
  value = aws_lb.alb01.dns_name
}

output "app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "target_group_arn" {
  value = aws_lb_target_group.tg01.arn
}

output "acm_cert_arn" {
  value = aws_acm_certificate.alb_acm_cert01.arn
}

output "waf_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.waf01[0].arn : null
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.dashboard01.dashboard_name
}

#--------------BONUS C OUTPUTS-----------------------------

output "route53_zone_id" {
  value = data.aws_route53_zone.zone.zone_id
}

output "app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

#---------BONUS D OUTPUTS--------------------------------

output "apex_url_https" {
  value = "https://${var.domain_name}"
}

output "alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs_bucket01[0].bucket : null
}

#------------BONUS E # OUTPUTS---------------

output "waf_log_destination" { 
  value = var.waf_log_destination 
}

output "waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.waf_log_group01[0].name : null
}

output "waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.waf_logs_bucket01[0].bucket : null
}

output "waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.waf_firehose01[0].name : null
}

# Lab 2 CloudFront outputs — DISABLED for Tokyo (no CloudFront in this region).

#------------LAB 3 OUTPUTS (consumed by Liberdade/São Paulo via remote state / variables)---------------

output "shinjuku_vpc_cidr" {
  description = "Shinjuku (Tokyo) VPC CIDR — consumed by Liberdade for TGW routes and SG rules"
  value       = var.vpc_cidr
}

output "shinjuku_tgw_id" {
  description = "Shinjuku Transit Gateway ID"
  value       = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

output "shinjuku_peering_attachment_id" {
  description = "TGW peering attachment ID — Liberdade needs this to accept"
  value       = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
}

output "shinjuku_rds_endpoint" {
  description = "Shinjuku (Tokyo) RDS endpoint — Liberdade app connects here (all PHI stays in Tokyo)"
  value       = aws_db_instance.rds01.address
}
