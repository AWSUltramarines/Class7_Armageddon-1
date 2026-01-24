resource "aws_sns_topic" "ops_alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "sms"
  endpoint  = var.alert_phone_e164
}

output "sns_topic_arn" {
  value = aws_sns_topic.ops_alerts.arn
}
