# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "app_db_logs" {
  name              = "/aws/ec2/db-connection-errors"
  retention_in_days = 30

  tags = {
    Environment = "development"
  }
}

resource "aws_cloudwatch_log_metric_filter" "db_connection_errors" {
  name           = "dbconnectionerrors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app_db_logs.name

  metric_transformation {
    name      = "dbconnectionerrors"
    namespace = "armageddon/labapp"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "db_fail_filter" {
  name           = "DBConnectionFailureCount"
  pattern        = "? \"Connection refused\" ? \"Timeout\" ? \"Login failed\""
  log_group_name = aws_cloudwatch_log_group.app_db_logs.name

  metric_transformation {
    name      = "dbConnectionErrors"
    namespace = "armageddon/labapp"
    value     = "1" # Increment by 1 for every match
  }
}


# # Alarm that fires when errors exceed threshold
resource "aws_cloudwatch_metric_alarm" "db_connection_alarm" {
  alarm_name          = "db-connection-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "armageddon/labapp"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "This alarm monitords DB connection errors exceed 3 in 1 minute"

  tags = {
    Project = "armageddon"
  }


# Connect to an SNS Topic for notifications
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  treat_missing_data  = "notBreaching" # Prevents false alarms if no logs are sent
}

resource "aws_sns_topic" "alerts" {
  name = "db-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "josunde15@gmail.com" # Change this to your actual email
}