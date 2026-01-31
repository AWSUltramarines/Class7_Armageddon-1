resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/lab/rdsapp"

  retention_in_days = 7

}

# METRIC FILTER PATTERN: Looks for error patterns in the logs
resource "aws_cloudwatch_log_metric_filter" "db_failure" {
  name           = "db_connection_failure_metric_filter"
  pattern        = "\"Database connection failed\"" # Search string
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "DBConnectionFailures"
    namespace = "Lab/RDSApp"
    value     = "1" # Add 1 to the count every time this pattern is found
    unit      = "Count"
  }
}

resource "aws_sns_topic" "db_incidents" {
  name         = "lab_db_incidents"
  display_name = "Lab DB Incidents"

}

# Email subscription for SNS Alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = "j.cramer2011@gmail.com"
}


# CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "db_failure_alarm" {
  alarm_name          = "lab_db_failure_alarm"
  alarm_description   = "Triggers when DB connection failures occur"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  metric_name         = "DBConnectionFailures"
  namespace           = "Lab/RDSApp"
  statistic           = "Sum"
  threshold           = 1
  evaluation_periods  = 1
  period              = 60
  datapoints_to_alarm = 1
  
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.db_incidents.arn]
  ok_actions    = [aws_sns_topic.db_incidents.arn]

}