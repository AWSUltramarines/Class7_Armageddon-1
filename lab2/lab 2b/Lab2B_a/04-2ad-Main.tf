############################################
# LAB 2A: WAF LOGGING FOR CLOUDFRONT WAF
############################################
# CloudWatch is recommended for CloudFront WAF because:
# - WAF logs must go to us-east-1 for CLOUDFRONT scope
# - CloudWatch in us-east-1 keeps everything in one region
# - Easier to query with Logs Insights

# CloudWatch Log Group (MUST be in us-east-1, MUST start with "aws-waf-logs-")
resource "aws_cloudwatch_log_group" "helga_cf_waf_logs" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project_name}-cf"
  retention_in_days = 30

  tags = { Name = "${var.project_name}-cf-waf-logs" }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "helga_cf_waf_logging" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.helga_cf_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.helga_cf_waflab2a.arn
}