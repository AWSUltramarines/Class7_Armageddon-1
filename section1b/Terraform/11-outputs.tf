output "ip_address" {
  value = aws_instance.web-lab-app.public_ip
}

output "website_user" {
  value = "http://${aws_instance.web-lab-app.public_dns}"
}

output "parameter_store_endpoint" {
  value = aws_ssm_parameter.db_endpoint.name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.app_log_group.name
}

output "cloudwatch_alarm" {
  value = aws_cloudwatch_metric_alarm.db_connection_alarm.alarm_name
}

output "secrets_manager_secret" {
  value = aws_secretsmanager_secret.app_db_secret.name
}