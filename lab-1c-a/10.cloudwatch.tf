resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/ec2/lab-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group"
  }
}

resource "aws_cloudwatch_log_metric_filter" "db_failure" {
  name           = "DBConnectionFailureFilter"
  pattern        = "?\"Database connection failed\"" # Search string
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name      = "DBConnectionFailures"
    namespace = "Lab/RDSApp"
    value     = "1" # Add 1 to the count every time this pattern is found
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_alarm" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionFailures"
  namespace           = "Lab/RDSApp"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.sns_topic.arn]
  ok_actions    = [aws_sns_topic.sns_topic.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}