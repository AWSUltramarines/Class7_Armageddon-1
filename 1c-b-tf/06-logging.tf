resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/ec2/lab-rds-app"

  # Clean up logs after 7 days
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-lab-rds-app-logs"
  }
}

# THE FILTER: Looks for error patterns in the logs
resource "aws_cloudwatch_log_metric_filter" "db_failure" {
  name           = "DBConnectionFailureFilter"
  pattern        = "\"Database connection failed\"" # Search string
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "DBConnectionFailures"
    namespace = "Lab/RDSApp"
    value     = "1" # Add 1 to the count every time this pattern is found
    unit      = "Count"
  }
}

# ================================================================ #

resource "aws_sns_topic" "db_incidents" {
  name         = "lab_db_incidents"
  display_name = "Lab DB Incidents"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-incidents-topic"
  }
}

# Email subscription for SNS topic (requires email confirmation)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ================================================================ #

# THE ALARM: Triggers if failures > 0
resource "aws_cloudwatch_metric_alarm" "db_failure_alarm" {
  alarm_name          = "lab-db-connection-failure"
  alarm_description   = "Triggers when DB connection failures occur"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  metric_name         = "DBConnectionFailures"
  namespace           = "Lab/RDSApp"
  statistic           = "Sum"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60 # Check every 60 seconds
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.db_incidents.arn]
  ok_actions    = [aws_sns_topic.db_incidents.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-lab-rds-app-alarm"
  }
}
