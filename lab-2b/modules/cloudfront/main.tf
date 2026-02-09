#####################################################
##### CLOUDFRONT
#####################################################
resource "aws_cloudfront_distribution" "cf_distro" {
  enabled         = true
  is_ipv6_enabled = true
  # comment             = "Some comment"
  web_acl_id = var.cf_waf_acl_arn
  # price_class = "PriceClass_100"


  origin {
    domain_name = var.alb_dns_name
    origin_id   = "${var.name_prefix}-alb-origin"


    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      # origin_protocol_policy = "http-only" # For testing
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
    custom_header {
      name  = "X-Custom-Header"
      value = var.cf_header_pw
    }
  }
  ######### Lab-2b
  ######### Updated Caching Behavior
  ##########################################################################
  default_cache_behavior {
    target_origin_id       = "${var.name_prefix}-alb-origin"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    # LAB 2B: Attach API Policies
    cache_policy_id          = aws_cloudfront_cache_policy.api_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_request.id

  }

  # B) Ordered Behavior: Target the /static folder for performance
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.name_prefix}-alb-origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    # LAB 2B: Attach Static Policies
    cache_policy_id = aws_cloudfront_cache_policy.static_optimized.id
    # Addition from Claude
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.static_request.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.static_security.id
  }

  # Addition from Claude
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "${var.name_prefix}-alb-origin"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.api_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_request.id
  }
  ###############################################################

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
#####################################################
##### CLOUDFRONT CACHING (Lab-2b)
#####################################################
# 1. Cache Policy for Static Content (Aggressive)
resource "aws_cloudfront_cache_policy" "static_optimized" {
  name        = "${var.name_prefix}-static-cache-policy"
  comment     = "Policy for high-performance static asset caching"
  default_ttl = 86400    # 24 hours
  max_ttl     = 31536000 # 1 year
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
    # Failure C Fix: Disabling these prevents cache fragmentation

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# 2. Cache Policy for API (Disabled)
resource "aws_cloudfront_cache_policy" "api_disabled" {
  name        = "${var.name_prefix}-api-no-cache"
  comment     = "Safe default: ensures API calls always hit the origin"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

# Static Origin Request Policy (Minimal)
# Addition from Claude
resource "aws_cloudfront_origin_request_policy" "static_request" {
  name    = "${var.name_prefix}-static-origin-policy"
  comment = "Minimal forwarding for static assets"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"] # Only Host header for SSL/SNI
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

# 3. Origin Request Policy for API (Forward what the Flask app needs)
resource "aws_cloudfront_origin_request_policy" "api_request" {
  name    = "${var.name_prefix}-api-origin-policy"
  comment = "Forwards Auth and Query Strings to the ALB"

  cookies_config { cookie_behavior = "all" }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Accept"]
    }
  }
  query_strings_config { query_string_behavior = "all" }
}

# 4. Be A Man Challenge: Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "static_security" {
  name    = "${var.name_prefix}-static-headers"
  comment = "Enforces secure Cache-Control for static assets"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=31536000, immutable"
    }
  }

  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
  }
}