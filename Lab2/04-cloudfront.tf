# Data source for CloudFront prefix list (used in ALB SG)
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_cloudfront_distribution" "helga_cf_distlab2a" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} CloudFront Distribution"
  default_root_object = "index.html"
  aliases             = [var.domain_name, local.helga_app_fqdn]
  price_class         = "PriceClass_100"
  web_acl_id          = aws_wafv2_web_acl.helga_cf_waflab2a.arn

  origin {
    domain_name = aws_lb.helga_alblab2a.dns_name
    origin_id   = "ALBOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Secret header for origin cloaking (defense-in-depth)
    custom_header {
      name  = var.origin_secret_header_name
      value = var.cloudfront_origin_secret
    }
  }
 

default_cache_behavior {
  # ...
  cache_policy_id          = aws_cloudfront_cache_policy.helga_cache_api_disabled01.id
  origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer.id
  #Review this portion to below confirm correctness
  viewer_protocol_policy = "redirect-to-https"
  cached_methods = ["GET", "HEAD"]
  target_origin_id = "ALBOrigin"
  allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}


# Add this ordered_cache_behavior block for static:
ordered_cache_behavior {
  path_pattern               = "/static/*"
  allowed_methods            = ["GET", "HEAD", "OPTIONS"]
  cached_methods             = ["GET", "HEAD"]
  target_origin_id           = "ALBOrigin"
  viewer_protocol_policy     = "redirect-to-https"
  compress                   = true
  
 #static content caching Lab 2b
  cache_policy_id              = aws_cloudfront_cache_policy.helga_cache_static01.id 
#orderd cache behavior caching lab 2ba

  origin_request_policy_id     = aws_cloudfront_origin_request_policy.helga_orp_static01.id
  response_headers_policy_id   = aws_cloudfront_response_headers_policy.helga_response_headers01.id
}

# Honors A: Origin-driven caching for /api/public-feed
ordered_cache_behavior {
  path_pattern               = "/api/public-feed"
  allowed_methods            = ["GET", "HEAD", "OPTIONS"]
  cached_methods             = ["GET", "HEAD"]
  target_origin_id           = "ALBOrigin"
  viewer_protocol_policy     = "redirect-to-https"
  compress                   = true

  cache_policy_id            = aws_cloudfront_cache_policy.helga_cache_origin_driven01.id
  origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.managed_all_viewer.id
}
#existing settings ... below

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

 viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.helga_cf_cert_validationlab2a.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = { Name = "${var.project_name}-cf-distlab2a" }

  depends_on = [aws_acm_certificate_validation.helga_cf_cert_validationlab2a]
}

############################################
# LAB 2A: CLOUDFRONT-SCOPED WAF WEB ACL
############################################

resource "aws_wafv2_web_acl" "helga_cf_waflab2a" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-cf-waflab2a"
  description = "CloudFront WAF for ${var.project_name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-cf-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

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
      metric_name                = "${var.project_name}-cf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-cf-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cf-waflab2a"
    sampled_requests_enabled   = true
  }

  tags = { Name = "${var.project_name}-cf-waflab2a" }
}