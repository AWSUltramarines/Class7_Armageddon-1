# --- Security Group change notifications ---
resource "aws_cloudwatch_event_rule" "sg_changes" {
  name        = "lab-sg-changes"
  description = "Alert on security group changes (via CloudTrail API calls)"

  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": [
        "AuthorizeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupIngress",
        "RevokeSecurityGroupEgress",
        "CreateSecurityGroup",
        "DeleteSecurityGroup",
        "UpdateSecurityGroupRuleDescriptionsIngress",
        "UpdateSecurityGroupRuleDescriptionsEgress",
        "ModifySecurityGroupRules"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "sg_changes_to_sns" {
  rule      = aws_cloudwatch_event_rule.sg_changes.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ops_alerts.arn
}

resource "aws_sns_topic_policy" "allow_eventbridge_publish" {
  arn = aws_sns_topic.ops_alerts.arn

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowEventBridgePublish",
        "Effect": "Allow",
        "Principal": { "Service": "events.amazonaws.com" },
        "Action": "sns:Publish",
        "Resource": aws_sns_topic.ops_alerts.arn
      }
    ]
  })
}

# --- Route Table change notifications ---
resource "aws_cloudwatch_event_rule" "route_table_changes" {
  name        = "lab-route-table-changes"
  description = "Alert on route table changes (via CloudTrail API calls)"

  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": [
        "CreateRoute",
        "ReplaceRoute",
        "DeleteRoute",
        "CreateRouteTable",
        "DeleteRouteTable",
        "AssociateRouteTable",
        "DisassociateRouteTable",
        "ReplaceRouteTableAssociation"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "route_table_changes_to_sns" {
  rule      = aws_cloudwatch_event_rule.route_table_changes.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ops_alerts.arn
}
