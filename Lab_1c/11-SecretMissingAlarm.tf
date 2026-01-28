resource "aws_cloudwatch_metric_alarm" "secret_missing_alarm" {
  alarm_name          = "lab-secret-missing"
  alarm_description   = "Triggers when the app logs missing/failed Secrets Manager secret access"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  evaluation_periods = 1
  period             = 60
  statistic          = "Sum"

  metric_name = aws_cloudwatch_log_metric_filter.secret_missing.metric_transformation[0].name
  namespace   = aws_cloudwatch_log_metric_filter.secret_missing.metric_transformation[0].namespace

  treat_missing_data = "notBreaching"
  alarm_actions = [aws_sns_topic.ops_alerts.arn]
  ok_actions    = [aws_sns_topic.ops_alerts.arn]
}


resource "aws_cloudwatch_log_metric_filter" "secret_missing" {
  name           = "lab-secret-missing"
  log_group_name = aws_cloudwatch_log_group.app.name



  # Common boto3 errors: ResourceNotFoundException / secretsmanager GetSecretValue failures
  pattern = "?\"ResourceNotFoundException\" ?\"Secrets Manager\" ?\"GetSecretValue\""
  # pattern = "\"ResourceNotFoundException\" || \"Secrets Manager\" || \"GetSecretValue\""

  metric_transformation {
    name      = "SecretMissingCount"
    namespace = "Lab/RDSApp"
    value     = "1"
  }
}





 


