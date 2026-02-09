resource "aws_wafv2_web_acl" "main" {
  name        = "ras-colservices-waf"
  scope       = "REGIONAL" # Use CLOUDFRONT if using CloudFront
  description = "Basic WAF for ALB"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAF_Common_Rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ras-colservices-waf-main"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = aws_lb.ras-colservices_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}