# outputs.tf - Useful outputs for verification and testing
#
# Lab 1c changes:
# - Removed: SSH-related outputs (ssh_connection, ssh_private_key)
# - Removed: ec2_public_ip, ec2_public_dns (EC2 is private)
# - EC2 and ALB outputs now conditional on enable_ec2 / exposure_mode
# - Added: Release management outputs (deps bucket, channel, prefixes)
# - Added: SSM port-forward command for airgap mode
# - Added: Workflow commands for release pipeline

# -----------------------------------------------------------------------------
# EC2 Outputs (conditional on enable_ec2)
# -----------------------------------------------------------------------------
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = var.enable_ec2 ? aws_instance.web[0].id : null
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = var.enable_ec2 ? aws_instance.web[0].private_ip : null
}

# -----------------------------------------------------------------------------
# Session Manager Access
# -----------------------------------------------------------------------------
output "ssm_session_command" {
  description = "Command to start SSM Session Manager session"
  value       = var.enable_ec2 ? "aws ssm start-session --target ${aws_instance.web[0].id}" : null
}

output "ssm_port_forward_command" {
  description = "Command to port-forward the Flask app via SSM (airgap mode)"
  value       = var.enable_ec2 ? "aws ssm start-session --target ${aws_instance.web[0].id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"80\"],\"localPortNumber\":[\"8080\"]}'" : null
}

# -----------------------------------------------------------------------------
# ALB Outputs (public_alb mode only)
# -----------------------------------------------------------------------------
output "alb_dns_name" {
  description = "ALB DNS name for application access (public_alb mode only)"
  value       = local.is_airgap ? null : aws_lb.app[0].dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = local.is_airgap ? null : aws_lb.app[0].arn
}

output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = local.is_airgap ? null : aws_lb_target_group.app[0].arn
}

output "app_url" {
  description = "Application access URL (ALB in public_alb mode, localhost via SSM in airgap mode)"
  value       = local.is_airgap ? "http://localhost:8080 (via SSM port-forward)" : "http://${aws_lb.app[0].dns_name}"
}

output "app_endpoints" {
  description = "Application endpoint URLs"
  value = local.is_airgap ? {
    health = "http://localhost:8080/health (via SSM port-forward)"
    init   = "http://localhost:8080/init"
    add    = "http://localhost:8080/add?note=YOUR_NOTE_HERE"
    list   = "http://localhost:8080/list"
    } : {
    health = "http://${aws_lb.app[0].dns_name}/health"
    init   = "http://${aws_lb.app[0].dns_name}/init"
    add    = "http://${aws_lb.app[0].dns_name}/add?note=YOUR_NOTE_HERE"
    list   = "http://${aws_lb.app[0].dns_name}/list"
  }
}

# -----------------------------------------------------------------------------
# S3 Dependencies Bucket
# -----------------------------------------------------------------------------
output "deps_bucket_name" {
  description = "Name of the S3 bucket containing offline dependencies"
  value       = aws_s3_bucket.deps.id
}

output "deps_bucket_arn" {
  description = "ARN of the dependencies S3 bucket"
  value       = aws_s3_bucket.deps.arn
}

# -----------------------------------------------------------------------------
# Release Management
# -----------------------------------------------------------------------------
output "release_id" {
  description = "Current release identifier"
  value       = var.release_id
}

output "channel" {
  description = "Deployment channel used by EC2 instances"
  value       = var.channel
}

output "release_prefixes" {
  description = "S3 prefixes for the current release"
  value = {
    rpm      = "s3://${aws_s3_bucket.deps.id}/${local.release_prefix_rpm}/"
    pip      = "s3://${aws_s3_bucket.deps.id}/${local.release_prefix_pip}/"
    cw_agent = "s3://${aws_s3_bucket.deps.id}/${local.release_prefix_cw_agent}/"
    manifest = "s3://${aws_s3_bucket.deps.id}/${local.manifest_prefix}/${var.release_id}.json"
  }
}

output "channel_pointers" {
  description = "S3 paths to channel pointer objects"
  value = {
    rpm_dev        = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_rpm}/dev"
    rpm_stage      = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_rpm}/stage"
    rpm_prod       = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_rpm}/prod"
    pip_dev        = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_pip}/dev"
    pip_stage      = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_pip}/stage"
    pip_prod       = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_pip}/prod"
    cw_agent_dev   = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_cw_agent}/dev"
    cw_agent_stage = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_cw_agent}/stage"
    cw_agent_prod  = "s3://${aws_s3_bucket.deps.id}/${local.channel_prefix_cw_agent}/prod"
  }
}

output "upload_command" {
  description = "Command to upload release artifacts to S3"
  value       = "./tools/1-upload_release.sh ${var.release_id} ${aws_s3_bucket.deps.id}"
}

# -----------------------------------------------------------------------------
# RDS Outputs
# -----------------------------------------------------------------------------
output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "RDS MySQL hostname"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.mysql.identifier
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# -----------------------------------------------------------------------------
# SSM Parameter Store Outputs
# -----------------------------------------------------------------------------
output "ssm_param_endpoint" {
  description = "SSM Parameter Store parameter name for DB endpoint"
  value       = aws_ssm_parameter.db_endpoint.name
}

output "ssm_param_port" {
  description = "SSM Parameter Store parameter name for DB port"
  value       = aws_ssm_parameter.db_port.name
}

output "ssm_param_name" {
  description = "SSM Parameter Store parameter name for DB name"
  value       = aws_ssm_parameter.db_name.name
}

# -----------------------------------------------------------------------------
# CloudWatch Outputs
# -----------------------------------------------------------------------------
output "log_group_name" {
  description = "CloudWatch Logs log group name"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "log_group_arn" {
  description = "CloudWatch Logs log group ARN"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "alarm_name" {
  description = "CloudWatch alarm name for DB connection errors"
  value       = aws_cloudwatch_metric_alarm.db_connection_errors.alarm_name
}

output "alarm_arn" {
  description = "CloudWatch alarm ARN"
  value       = aws_cloudwatch_metric_alarm.db_connection_errors.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for incident notifications"
  value       = aws_sns_topic.db_incidents.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.db_incidents.name
}

output "sns_subscription_arn" {
  description = "SNS email subscription ARN (PendingConfirmation until email confirmed)"
  value       = var.alert_email != "" ? aws_sns_topic_subscription.email_alerts[0].arn : "No email subscription (alert_email variable not set)"
}

output "sns_subscription_status" {
  description = "Instructions for confirming email subscription"
  value       = var.alert_email != "" ? "Email subscription created for ${var.alert_email}. Check your inbox and confirm the subscription." : "No email subscription configured. Set alert_email variable to receive notifications."
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "alb_security_group_id" {
  description = "ALB security group ID (public_alb mode only)"
  value       = local.is_airgap ? null : aws_security_group.alb[0].id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "vpc_endpoints_security_group_id" {
  description = "VPC Endpoints security group ID"
  value       = aws_security_group.vpc_endpoints.id
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (public_alb mode only)"
  value       = local.is_airgap ? [] : aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EC2 and RDS)"
  value       = aws_subnet.private[*].id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# VPC Endpoint Outputs
# -----------------------------------------------------------------------------
output "vpc_endpoint_ids" {
  description = "VPC Interface Endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "vpc_endpoint_s3_id" {
  description = "S3 Gateway Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------
output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_iam_role_name" {
  description = "EC2 IAM role name"
  value       = aws_iam_role.ec2.name
}

# -----------------------------------------------------------------------------
# AMI Information
# -----------------------------------------------------------------------------
output "ami_used" {
  description = "AMI ID used for EC2 instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "ami_name" {
  description = "AMI name used for EC2 instance"
  value       = data.aws_ami.amazon_linux_2023.name
}

# -----------------------------------------------------------------------------
# Mode Information
# -----------------------------------------------------------------------------
output "exposure_mode" {
  description = "Current exposure mode (airgap or public_alb)"
  value       = var.exposure_mode
}

# -----------------------------------------------------------------------------
# Verification Command Helpers
# -----------------------------------------------------------------------------
output "verification_commands" {
  description = "AWS CLI commands for Lab 1c verification"
  value = merge(
    # Common commands (both modes)
    {
      # Prove EC2 is private
      check_ec2_no_public_ip = var.enable_ec2 ? "aws ec2 describe-instances --instance-ids ${aws_instance.web[0].id} --query 'Reservations[].Instances[].PublicIpAddress'" : null

      # Prove VPC endpoints exist
      check_vpc_endpoints = "aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values=${aws_vpc.main.id}' --query 'VpcEndpoints[].ServiceName'"

      # Prove Session Manager works
      check_ssm_status = var.enable_ec2 ? "aws ssm describe-instance-information --filters 'Key=InstanceIds,Values=${aws_instance.web[0].id}' --query 'InstanceInformationList[].{InstanceId:InstanceId,PingStatus:PingStatus}'" : null

      # Start Session Manager session
      start_session = var.enable_ec2 ? "aws ssm start-session --target ${aws_instance.web[0].id}" : null

      # Check RDS status
      check_rds = "aws rds describe-db-instances --db-instance-identifier ${aws_db_instance.mysql.identifier} --query 'DBInstances[].{Status:DBInstanceStatus,Endpoint:Endpoint}'"

      # Check CloudWatch logs
      check_logs = "aws logs describe-log-streams --log-group-name ${var.log_group_name} --order-by LastEventTime --descending --max-items 3"

      # Check alarm state
      check_alarm = "aws cloudwatch describe-alarms --alarm-names ${aws_cloudwatch_metric_alarm.db_connection_errors.alarm_name} --query 'MetricAlarms[0].StateValue'"

      # Check SSM parameters from inside EC2 (run in SSM session)
      ssm_session_check_params = "aws ssm get-parameter --name ${local.ssm_param_db_endpoint}"

      # Check secrets from inside EC2 (run in SSM session)
      ssm_session_check_secret = "aws secretsmanager get-secret-value --secret-id ${var.secret_name} --query SecretString --output text | jq ."
    },
    # Airgap-specific commands
    local.is_airgap ? {
      # Port-forward to access Flask app
      port_forward = var.enable_ec2 ? "aws ssm start-session --target ${aws_instance.web[0].id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"80\"],\"localPortNumber\":[\"8080\"]}'" : null

      # Test via port-forward (run after port_forward in another terminal)
      check_app_health = "curl -s http://localhost:8080/health"

      # Verify no internet gateway
      check_no_igw = "aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values=${aws_vpc.main.id}' --query 'InternetGateways'"
      } : {
      # ALB-specific commands (public_alb mode)
      check_alb_health = "curl -s http://${aws_lb.app[0].dns_name}/health"
    }
  )
}

# -----------------------------------------------------------------------------
# Workflow Commands
# -----------------------------------------------------------------------------
output "workflow_commands" {
  description = "Commands for release management workflow"
  value = {
    build_release   = "./tools/0-build_release.sh <release_id>"
    upload_release  = "./tools/1-upload_release.sh ${var.release_id} ${aws_s3_bucket.deps.id}"
    promote_to_prod = "./tools/2-promote_channel.sh prod ${var.release_id} ${aws_s3_bucket.deps.id}"
    rollback_prod   = "./tools/3-rollback_channel.sh prod <previous_release_id> ${aws_s3_bucket.deps.id}"
    refresh_ec2     = var.enable_ec2 ? "terraform taint 'aws_instance.web[0]' && terraform apply" : "Set enable_ec2=true first"
    check_logs      = var.enable_ec2 ? "aws logs tail ${aws_cloudwatch_log_group.app_logs.name} --follow --region ${var.aws_region}" : null
  }
}
