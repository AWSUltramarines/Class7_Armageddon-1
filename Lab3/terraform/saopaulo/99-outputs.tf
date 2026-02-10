output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "The final URL to access your application"
  value       = "https://${var.subdomain_name}.${var.domain_name}"
}

output "alb_arn" {
  description = "The ARN of the ALB (Required for CLI verification)"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "The ARN of the Target Group (Required for CLI verification)"
  value       = aws_lb_target_group.flask_app.arn
}

# output "acm_certificate_status" {
#   description = "The status of the SSL certificate"
#   value       = aws_acm_certificate.cert.status
# }

output "route53_zone_id" {
  description = "The Hosted Zone ID for your domain verification"
  # References the dynamic lookup from 07-alb-dns.tf
  value = data.aws_route53_zone.main.zone_id
}

output "app_url_https" {
  description = "The final secure URL for your application"
  value       = "https://${local.app_fqdn}"
}

# output "certificate_arn" {
#   description = "The ARN of the ACM certificate"
#   value       = aws_acm_certificate.cert.arn
# }

output "daequan_apex_url_https" {
  description = "The root domain URL"
  value       = "https://${var.domain_name}"
}

output "alb_logs_bucket_name" {
  description = "The S3 bucket storing access logs"
  value       = var.enable_alb_access_logs ? aws_s3_bucket.alb_logs.bucket : null
}

# The WAF logging destination type (cloudwatch, s3, or firehose)
output "waf_log_destination" {
  value = var.waf_log_destination
}

# The CloudWatch Log Group name for WAF logs (null if using S3 instead)
output "waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? try(aws_cloudwatch_log_group.waf_log_group[0].name, null) : null
}

# The secret header value used for CloudFront-to-ALB origin validation
output "origin_header_value" {
  value     = random_password.origin_header.result
  sensitive = true
}

output "saopaulo_tgw_id" {
  description = "The ID of the Sao Paulo Transit Gateway for peering with Tokyo"
  value       = aws_ec2_transit_gateway.saopaulo.id
}
# ================================================================ #
# Lab 3B: Audit Evidence Outputs
# ================================================================ #

output "cloudtrail_bucket_name" {
  description = "S3 bucket storing CloudTrail logs for audit evidence"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_trail_arn" {
  description = "ARN of the São Paulo CloudTrail trail"
  value       = aws_cloudtrail.saopaulo_trail.arn
}

output "vpc_flow_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "vpc_id" {
  description = "São Paulo VPC ID for audit evidence"
  value       = aws_vpc.main.id
}

output "tgw_id" {
  description = "São Paulo Transit Gateway ID"
  value       = aws_ec2_transit_gateway.saopaulo.id
}

output "tgw_vpc_attachment_id" {
  description = "São Paulo TGW VPC Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.saopaulo_vpc.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN for audit evidence"
  value       = aws_wafv2_web_acl.main.arn
}