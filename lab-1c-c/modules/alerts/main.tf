######################################
###### CloudWatch Alarms & SNS Topic
######################################
resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/ec2/lab-rds-app"

  # Clean up logs after 7 days
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-lab-rds-app-logs"
  }
}

# Looks for error patterns in the logs
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

resource "aws_sns_topic" "db_incidents" {
  name         = "lab_db_incidents"
  display_name = "Lab DB Incidents"

  tags = {
    Name = "${var.name_prefix}-db-incidents-topic"
  }
}

resource "aws_sns_topic_subscription" "sns_sub" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = var.sns_endpoint_protocol
  endpoint  = var.sns_sub_endpoint

}

###################################################################
# This alarm triggers if failures > 0
resource "aws_cloudwatch_metric_alarm" "db_failure_alarm" {
  alarm_name          = "lab-db-connection-failure"
  alarm_description   = "Triggers when DB connection failures occur"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  metric_name         = "DBConnectionFailures"
  namespace           = "Lab/RDSApp"
  statistic           = "Sum"
  threshold           = 0  # Trigger if failures are greater than 0
  evaluation_periods  = 1  # check over 1 period
  period              = 60 # Check every 60 seconds
  datapoints_to_alarm = 1  # Alarm if 1 out of 1 datapoints are breaching

  treat_missing_data = "notBreaching" # Ignore missing data

  alarm_actions = [aws_sns_topic.db_incidents.arn]
  ok_actions    = [aws_sns_topic.db_incidents.arn]

  tags = {
    Name = "${var.name_prefix}-lab-rds-app-alarm"
  }
}

##############################################
###### Cloud Watch Dashboard
##############################################

# This alarm triggers if ALB returns 5xx errors (Server Errors)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_alarm" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0" # Trigger if even 1 error occurs
  alarm_description   = "This alarm triggers if the ALB returns any 5xx errors."

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.db_incidents.arn]
  ok_actions    = [aws_sns_topic.db_incidents.arn]
}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-app-health"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: EC2 CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EC2 CPU Utilization (%)"
        }
      },
      # Widget 2: ALB Request Count
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.region
          title  = "Total ALB Requests"
        }
      },
      # Widget 3: Target Response Time (Latency)
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "Avg App Response Time (ms)"
        }
      },
      # Widget 4: ALB 5xx Errors
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.region
          title  = "ALB 5xx Server Errors"
          color  = "#d62728" # Red for errors
        }
      }
    ]
  })
}