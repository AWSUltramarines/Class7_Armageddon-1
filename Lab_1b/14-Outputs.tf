output "ssm_parameter_names" {
  value = [
    aws_ssm_parameter.db_endpoint.name,
    aws_ssm_parameter.db_port.name,
    aws_ssm_parameter.db_name.name
  ]
}

# output "secrets_manager_secret_name" {
#   value = aws_secretsmanager_secret.db.name
# }

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.db_errors_alarm.alarm_name
}

# # output "ec2_instance_profile_name" {
#   value       = var.create_ec2_instance_profile ? aws_iam_instance_profile.ec2_profile[0].name : null
#   description = "Attach this instance profile to your EC2 instance (if Terraform didn't create the EC2 resource)."
# # }
