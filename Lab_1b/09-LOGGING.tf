resource "aws_cloudwatch_log_group" "app" {
  name              = var.app_log_group_name
  retention_in_days = 7
}

# Metric filter that counts ERROR occurrences in the log group
resource "aws_cloudwatch_log_metric_filter" "db_error_count" {
  name           = "lab-db-error-count"
  log_group_name = aws_cloudwatch_log_group.app.name

  # Simple filter pattern: looks for "ERROR"
  pattern = "ERROR"

  metric_transformation {
    name      = "DbConnectionErrorCount"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_errors_alarm" {
  alarm_name          = var.alarm_name
  alarm_description   = "Triggers when DB connection failures (ERROR logs) exceed threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.error_threshold

  evaluation_periods = var.alarm_evaluation_periods
  period             = var.alarm_period_seconds
  statistic          = "Sum"

  metric_name = aws_cloudwatch_log_metric_filter.db_error_count.metric_transformation[0].name
  namespace   = aws_cloudwatch_log_metric_filter.db_error_count.metric_transformation[0].namespace

  treat_missing_data = "notBreaching"
    alarm_actions = [aws_sns_topic.ops_alerts.arn]
    ok_actions    = [aws_sns_topic.ops_alerts.arn]

}

variable "alarm_evaluation_periods" {
  type    = number
  default = 5
}