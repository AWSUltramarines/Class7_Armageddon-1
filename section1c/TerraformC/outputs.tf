# Explanation: Outputs are your mission report—what got built and where to find it.
output "chewbacca_vpc_id" {
    value = aws_vpc.chewbacca_vpc01.id
}

output "chewbacca_public_subnet_ids" {
    value = aws_subnet.chewbacca_public_subnets[*].id
}

output "chewbacca_private_subnet_ids" {
    value = aws_subnet.chewbacca_private_subnets[*].id
}

output "chewbacca_ec2_instance_id" {
    value = aws_instance.chewbacca_ec201.id
}

output "chewbacca_rds_endpoint" {
    value = aws_db_instance.chewbacca_rds01.address
}

output "chewbacca_sns_topic_arn" {
    value = aws_sns_topic.chewbacca_sns_topic01.arn
}

output "chewbacca_log_group_name" {
    value = aws_cloudwatch_log_group.chewbacca_log_group01.name
}


# OPTION B - Replace with private IP output:
output "app_private_ip" {
    description = "Private IP of the Flask application (access via SSM or ALB)"
    value       = aws_instance.chewbacca_ec201.private_ip
}
#
# OPTION C - Add a note explaining the access method:
output "app_access_note" {
    description = "How to access the private application"
    value       = "Use SSM Session Manager: aws ssm start-session --target ${aws_instance.chewbacca_ec201.id}"
}


output "private_ec2_instance_id" {
    description = "EC2 Instance ID - use with describe-instances to verify no public IP"
    value       = aws_instance.chewbacca_ec201.id
}

output "vpc_id_for_endpoints" {
    description = "VPC ID - use with describe-vpc-endpoints to list all endpoints"
    value       = aws_vpc.chewbacca_vpc01.id
}

output "secret_name_for_verification" {
    description = "Secret name - use in SSM session to test GetSecretValue"
    value       = local.secret_name
}

output "verification_commands" {
    description = "CLI commands to verify your Bonus-A implementation"
    value = <<-EOT
    
    ============================================
    BONUS-A VERIFICATION COMMANDS
    ============================================
    
    1. PROVE EC2 HAS NO PUBLIC IP:
       aws ec2 describe-instances \
         --instance-ids ${aws_instance.chewbacca_ec201.id} \
         --query "Reservations[].Instances[].PublicIpAddress"
       Expected: null
    
    2. PROVE VPC ENDPOINTS EXIST:
       aws ec2 describe-vpc-endpoints \
         --filters "Name=vpc-id,Values=${aws_vpc.chewbacca_vpc01.id}" \
         --query "VpcEndpoints[].ServiceName"
       Expected: ssm, ssmmessages, ec2messages, logs, secretsmanager, kms, s3
    
    3. PROVE SSM SESSION MANAGER WORKS:
       aws ssm describe-instance-information \
         --query "InstanceInformationList[].InstanceId"
       Expected: ${aws_instance.chewbacca_ec201.id} appears
    
    4. CONNECT VIA SESSION MANAGER:
       aws ssm start-session --target ${aws_instance.chewbacca_ec201.id}
    
    5. FROM INSIDE SSM SESSION - TEST CONFIG ACCESS:
       aws ssm get-parameter --name /lab/db/endpoint --region ${var.aws_region}
       aws secretsmanager get-secret-value --secret-id ${local.secret_name} --region ${var.aws_region}
    
    6. PROVE CLOUDWATCH LOGS PATH:
       aws logs describe-log-streams \
         --log-group-name ${local.log_group}
    
    EOT
}

output "endpoint_summary" {
    description = "Summary of all VPC endpoints created"
    value = {
        interface_endpoints = {
            ssm            = aws_vpc_endpoint.chewbacca_vpce_ssm.id
            ssmmessages    = aws_vpc_endpoint.chewbacca_vpce_ssmmessages.id
            ec2messages    = aws_vpc_endpoint.chewbacca_vpce_ec2messages.id
            logs           = aws_vpc_endpoint.chewbacca_vpce_logs.id
            secretsmanager = aws_vpc_endpoint.chewbacca_vpce_secretsmanager.id
            kms            = aws_vpc_endpoint.chewbacca_vpce_kms.id
        }
        gateway_endpoints = {
            s3 = aws_vpc_endpoint.chewbacca_vpce_s3.id
        }
    }
}


# Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
output "chewbacca_alb_dns_name" {
  value = aws_lb.chewbacca_alb01.dns_name
}

output "chewbacca_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "chewbacca_target_group_arn" {
  value = aws_lb_target_group.chewbacca_tg01.arn
}

output "chewbacca_acm_cert_arn" {
  value = aws_acm_certificate.chewbacca_acm_cert01.arn
}

output "chewbacca_waf_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.chewbacca_waf01[0].arn : null
}

output "chewbacca_dashboard_name" {
  value = aws_cloudwatch_dashboard.chewbacca_dashboard01.dashboard_name
}

############################################
# BONUS-B OUTPUTS
############################################

# CRITICAL: Students must update their domain registrar with these nameservers
output "route53_nameservers" {
    description = "⚠️  CRITICAL: Update your domain registrar with these nameservers"
    value = aws_route53_zone.chewbacca_zone.name_servers
}

output "route53_zone_id" {
    description = "Route53 Hosted Zone ID for DNS management"
    value = aws_route53_zone.chewbacca_zone.zone_id
}

output "app_url_https" {
    description = "🚀 Your application HTTPS URL (after DNS propagation)"
    value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "app_url_http" {
    description = "HTTP URL (redirects to HTTPS)"
    value = "http://${var.app_subdomain}.${var.domain_name}"
}

output "acm_certificate_status" {
    description = "ACM Certificate validation status"
    value = aws_acm_certificate.chewbacca_acm_cert01.status
}

output "bonus_b_verification_commands" {
    description = "CLI commands to verify your Bonus-B implementation"
    value = <<-EOT
    
    ============================================
    BONUS-B VERIFICATION COMMANDS
    ============================================
    
    ⚠️  FIRST: Update your domain registrar nameservers to:
    ${join("\n    ", aws_route53_zone.chewbacca_zone.name_servers)}
    
    Wait 5-30 minutes for DNS propagation, then proceed:
    
    1. CONFIRM HOSTED ZONE EXISTS:
       aws route53 list-hosted-zones-by-name \
         --dns-name ${var.domain_name} \
         --query "HostedZones[].Id"
    
    2. CONFIRM DNS RECORDS EXIST:
       aws route53 list-resource-record-sets \
         --hosted-zone-id ${aws_route53_zone.chewbacca_zone.zone_id} \
         --query "ResourceRecordSets[?Name=='${var.app_subdomain}.${var.domain_name}.']"
    
    3. CONFIRM ACM CERTIFICATE ISSUED:
       aws acm describe-certificate \
         --certificate-arn ${aws_acm_certificate.chewbacca_acm_cert01.arn} \
         --query "Certificate.Status"
       Expected: "ISSUED"
    
    4. CONFIRM ALB IS HEALTHY:
       aws elbv2 describe-target-health \
         --target-group-arn ${aws_lb_target_group.chewbacca_tg01.arn}
       Expected: State = "healthy"
    
    5. TEST DNS RESOLUTION:
       nslookup ${var.app_subdomain}.${var.domain_name}
       dig ${var.app_subdomain}.${var.domain_name}
    
    6. TEST HTTPS ENDPOINT:
       curl -I https://${var.app_subdomain}.${var.domain_name}
       Expected: HTTP/2 200 OK (or 301/302 redirect)
    
    7. TEST HTTP → HTTPS REDIRECT:
       curl -I http://${var.app_subdomain}.${var.domain_name}
       Expected: HTTP/1.1 301 Moved Permanently
       Location: https://${var.app_subdomain}.${var.domain_name}
    
    8. TEST APPLICATION ENDPOINTS:
       curl https://${var.app_subdomain}.${var.domain_name}/
       curl https://${var.app_subdomain}.${var.domain_name}/init
       curl https://${var.app_subdomain}.${var.domain_name}/add?note=bonus-b-works
       curl https://${var.app_subdomain}.${var.domain_name}/list
    
    9. CONFIRM WAF IS ATTACHED (if enabled):
       aws wafv2 list-web-acls --scope=REGIONAL \
         --region ${var.aws_region}
    
    10. VIEW CLOUDWATCH DASHBOARD:
        aws cloudwatch get-dashboard \
          --dashboard-name ${aws_cloudwatch_dashboard.chewbacca_dashboard01.dashboard_name}
    
    ============================================
    🎯 SUCCESS CRITERIA
    ============================================
    ✅ ACM certificate status = "ISSUED"
    ✅ Target health = "healthy"
    ✅ HTTPS responds with 200 OK
    ✅ HTTP redirects to HTTPS (301)
    ✅ Application endpoints work via HTTPS
    ✅ WAF protects ALB (if enabled)
    ✅ CloudWatch dashboard shows metrics
    
    EOT
}
//output "chewbacca_route53_zone_id" { value = local.chewbacca_zone_id }

output "chewbacca_app_url_https" { value = "https://${var.app_subdomain}.${var.domain_name}" }