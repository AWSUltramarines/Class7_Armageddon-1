# Explanation: CloudFront is the only public doorway — Chewbacca stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-Jasongeddon-Growl"
      value = random_password.origin_header_value01.result
    }
  }

  # Default behavior is conservative — assumes dynamic/API until proven static.
  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id

    # Replaced by cache_policy_id and origin_request_policy_id above —
    # forwarded_values and cache policies are mutually exclusive in CloudFront.
    # forwarded_values {
    #   query_string = true
    #   headers      = ["*"]
    #   cookies { forward = "all" }
    # }
  }

  # Static behavior is the speed lane — aggressive caching for /static/* assets.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.rsp_static01.id
  }

  # API catch-all — safe default (no caching), forwards all needed context.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.cf_waf01.arn

  # TODO: students set aliases for chewbacca-growl.com and app.chewbacca-growl.com
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # Using existing ACM cert (acm_cert01) directly — it already covers both
  # app.jason-cramer.com and jason-cramer.com, and is in us-east-1 as CloudFront requires.
  # Original template used var.cloudfront_acm_cert_arn, but a separate variable is unnecessary.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.acm_validation01.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Variable below not needed — using existing acm_cert01 which already covers
# both domains and is in us-east-1 (required by CloudFront).
# variable "cloudfront_acm_cert_arn" {
#   description = "ACM certificate ARN in us-east-1 for CloudFront."
#   type        = string
# }

# Explanation: Chewbacca only opens the hangar to CloudFront — everyone else gets the Wookiee roar.
data "aws_ec2_managed_prefix_list" "cf_origin_facing01" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


# Explanation: Only CloudFront origin-facing IPs may speak to the ALB — direct-to-ALB attacks die here.
resource "aws_security_group_rule" "alb_ingress_cf44301" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg01.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.cf_origin_facing01.id
  ]
}



# Explanation: This is Chewbacca’s secret handshake — if the header isn’t present, you don’t get in.
resource "random_password" "origin_header_value01" {
  length  = 32
  special = false
}



# Explanation: ALB checks for Chewbacca’s secret growl — no growl, no service.
resource "aws_lb_listener_rule" "require_origin_header01" {
  listener_arn = aws_lb_listener.https_listener01.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Jasongeddon-Growl"
      values           = [random_password.origin_header_value01.result]
    }
  }
}

# Explanation: If you don’t know the growl, you get a 403 — Chewbacca does not negotiate.
resource "aws_lb_listener_rule" "default_block01" {
  listener_arn = aws_lb_listener.https_listener01.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern { values = ["*"] }
  }
}

# Explanation: DNS now points to CloudFront — nobody should ever see the ALB again.
resource "aws_route53_record" "apex_to_cf01" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# Explanation: app.chewbacca-growl.com also points to CloudFront — same doorway, different sign.
resource "aws_route53_record" "app_to_cf01" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# Explanation: The shield generator moves to the edge — CloudFront WAF blocks nonsense before it hits your VPC.
resource "aws_wafv2_web_acl" "cf_waf01" {
  name  = "${var.project_name}-cf-waf01"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cf-waf01"
    sampled_requests_enabled   = true
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
      metric_name                = "${var.project_name}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }
}