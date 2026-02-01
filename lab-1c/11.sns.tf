resource "aws_sns_topic" "sns_topic" {
  name         = "${local.name_prefix}-db-incidents"
  display_name = "DB Incident Notifications"
  tags = {
    Name = "${local.name_prefix}-db-incidents-topic"
  }
}

resource "aws_sns_topic_subscription" "sns_sub" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = var.sns_endpoint_protocol
  endpoint  = var.sns_sub_endpoint

}