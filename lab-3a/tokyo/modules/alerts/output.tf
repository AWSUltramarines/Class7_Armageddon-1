output "log_group_arn" {
  value = aws_cloudwatch_log_group.app_logs.arn
}
output "app_logs" {
  value = aws_cloudwatch_log_group.app_logs
}
output "app_logs_name" {
  value = aws_cloudwatch_log_group.app_logs.name
}