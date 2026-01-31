# Explanation: Outputs are your mission report—what got built and where to find it.
output "helga_vpc_id" {
  value = aws_vpc.helga_vpc01.id
}

output "helga_public_subnet_ids" {
  value = aws_subnet.helga_public_subnets[*].id
}

output "helga_private_subnet_ids" {
  value = aws_subnet.helga_private_subnets[*].id
}

/* output "helga_ec2_instance_id" {
  value = aws_instance.helga_ec201.id 
} 
*/

output "helga_rds_endpoint" {
  value = aws_db_instance.helga_rds01.address
}

output "helga_sns_topic_arn" {
  value = aws_sns_topic.helga_sns_topic01.arn
}

output "helga_log_group_name" {
  value = aws_cloudwatch_log_group.helga_log_group01.name
}
/* 
#Bonus B Outputs for ALB and Target Group
output "helga_alb_dns_name" {
  value = aws_lb.helga_alb01.dns_name
}

output "helga_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}
 */
/* # ============================================
# BONUS C: Route53 Outputs
# ============================================

output "helga_route53_zone_id" {
  value = local.helga_zone_id
}

output "helga_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

# ============================================
# BONUS D: Apex + Logging Outputs
# ============================================
output "helga_apex_url_https" {
  value = "https://${var.domain_name}"
}
output "helga_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.helga_alb_logs_bucket01[0].bucket : null
}

# ============================================
# BONUS E: WAF Logging Outputs
# ============================================
output "helga_waf_log_destination" {
  value = var.waf_log_destination
}

output "helga_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.helga_waf_log_group01[0].name : null
}

output "helga_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.helga_waf_logs_bucket01[0].bucket : null
}

output "helga_waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.helga_waf_firehose01[0].name : null
}

# Explanation: The WAF Web ACL ARN—needed for logging config verification and troubleshooting.
output "helga_waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (needed for get-logging-configuration command)"
  value       = var.enable_waf ? aws_wafv2_web_acl.helga_waf01[0].arn : null
} */