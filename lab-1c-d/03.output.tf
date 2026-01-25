############################################
# Locals & Data
############################################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

#############################################
######### Network Outputs
#############################################
output "vpc_id" {
  value = module.network.vpc_id
}
# output "private_subnet_ids" {
#   value = local.private_subnets[*]
# }
#############################################
######### Compute Outputs
#############################################
output "ec2_instance_id" {
  value = module.compute.ec2_instance_id
}
output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = module.compute.target_group_arn
}
output "rds_instance_endpoint" {
  value = module.database.rds_connection.endpoint
}
#############################################
######### Load Balancer Outputs
#############################################
output "alb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = module.load_balancer.alb.dns_name
}
output "alb_arn" {
  description = "The ARN of the ALB (Required for CLI verification)"
  value       = module.load_balancer.alb_arn
}
#############################################
######### Route53 Outputs
#############################################
output "application_url" {
  description = "The final URL to access your application"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}
output "apex_application_url" {
  description = "The final apex URL to access your application"
  value       = "https://${var.domain_name}"
}
output "acm_certificate_status" {
  description = "The status of the SSL certificate"
  value       = module.route53.acm_certificate_status
}
output "route53_zone_id" {
  description = "The Hosted Zone ID for your domain verification"
  value       = data.aws_route53_zone.main.zone_id
}
output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = module.route53.certificate_arn
}
#############################################
######### S3 Logs Outputs
#############################################
output "alb_logs_bucket_name" {
  description = "The name of the S3 bucket for ALB access logs"
  value       = module.s3bucket.s3_bucket
}