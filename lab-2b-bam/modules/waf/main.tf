#################################################################
### Data Sources
#################################################################
data "aws_caller_identity" "self" {}

data "aws_region" "region" {}
#################################################################
### WAF ACL FOR LOAD BALANCER
#################################################################
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-web-acl"
  description = "WAF for ALB to block common web attacks"
  scope       = "REGIONAL" # Use REGIONAL for ALB; CLOUDFRONT for CDN

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

################# Associate the WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
########################################
### WAF ACL FOR CLOUDFRONT
########################################
resource "aws_wafv2_web_acl" "cf_waf" {
  name  = "${var.name_prefix}-cf-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-cf-waf"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-cf-waf-common"
    sampled_requests_enabled   = true
  }
}
########################################
### WAF Logging Configuration
########################################
########### CloudWatch Toggle for WAF Logging
resource "aws_cloudwatch_log_group" "waf_log_group" {
  count             = var.waf_log_destination == "cloudwatch" ? 1 : 0
  name              = "aws-waf-logs-${var.name_prefix}-webacl"
  retention_in_days = 7
}
########### S3 Toggle for WAF Logging
resource "aws_s3_bucket" "waf_s3_logs" {
  count         = var.waf_log_destination == "s3" ? 1 : 0
  bucket        = "aws-waf-logs-${var.name_prefix}-${data.aws_caller_identity.self.account_id}"
  force_destroy = true
}
########### Toggle for WAF ACL Log 
########### Checks for CloudWatch or logs go to S3
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn = aws_wafv2_web_acl.main.arn

  log_destination_configs = [
    var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.waf_log_group[0].arn : aws_s3_bucket.waf_s3_logs[0].arn
  ]
}