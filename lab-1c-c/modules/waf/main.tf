# Create the Web ACL (The Firewall)
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-web-acl"
  description = "WAF for ALB to block common web attacks"
  scope       = "REGIONAL" # Use REGIONAL for ALB; CLOUDFRONT for CDN

  default_action {
    allow {}
  }

  # Add a managed rule set (ex: Core Rule Set for SQLi, XSS)
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
      metric_name                = "WAFCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.name_prefix}-waf"
  }
}

# Associate the WAF with your ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}