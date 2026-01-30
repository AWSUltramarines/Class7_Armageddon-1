# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "app_log_group" {
  # name              = "/aws/armageddon/app-logs"
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7

  tags = {
    Project     = "armageddon"
    Environment = "development"
  }
}

resource "aws_cloudwatch_log_metric_filter" "db_connection_errors" {
  name           = "dbconnectionerrors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name

  metric_transformation {
    name      = "dbconnectionerrors"
    namespace = "armageddon/labapp"
    value     = "1"
  }
}

# Alarm that fires when errors exceed threshold
resource "aws_cloudwatch_metric_alarm" "db_connection_alarm" {
  alarm_name          = "lab-db-connection-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "dbconnectionerrors"
  namespace           = "armageddon/labapp"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Triggers when DB connection errors exceed 3 in 1 minute"

  tags = {
    Project = "armageddon"
  }
}