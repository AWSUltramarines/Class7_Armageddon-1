# SNS Alert Channel ---
resource "aws_sns_topic" "alerts" {
  name = "lab-db-incidents" 
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email 
}

# ================================================================ #

# CloudWatch Alarm ---

# Log Group (Where the logs live)
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7
}

# Metric Filter

# This watches the logs for the word "ERROR" and counts it as "1"
resource "aws_cloudwatch_log_metric_filter" "db_errors" {
  name           = "DBConnectionErrorsFilter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name      = "DBConnectionErrors" 
    namespace = "Lab/RDSApp"         
    value     = "1"
  }
}

# ================================================================ #

# The Alarm (The Trigger)
resource "aws_cloudwatch_metric_alarm" "db_failure" {
  alarm_name          = "lab-db-connection-failure" 
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = "300" # 5 minutes
  statistic           = "Sum"
  threshold           = "3"   # 3 errors
  alarm_description   = "Alarm when DB connection fails > 3 times"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}