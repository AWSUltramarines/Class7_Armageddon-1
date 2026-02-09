#####################################################
##### CLOUDFRONT
#####################################################
resource "aws_cloudfront_distribution" "cf_distro" {
  enabled         = true
  is_ipv6_enabled = true
  # comment             = "Some comment"
  web_acl_id = var.cf_waf_acl_arn
  provider   = aws

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "${var.name_prefix}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    custom_header {
      name  = "X-Custom-Header"
      value = var.cf_header_pw
    }
  }
  # Changes to Lab 2b
  ##########################################################################
  default_cache_behavior {
    target_origin_id       = "${var.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.api-cache_disabled.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api.id
  }

  # Explanation: Static behavior is the speed lane—Chewbacca caches it hard for performance.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.static_cache.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.orp_static.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.rsp_static.id
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
##### DATA
#####################################################
# Instead of creating a custom policy, use AWS managed policy
# Use AWS managed policy for API (forwards all headers including Authorization)
data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}
#####################################################
##### CLOUDFRONT CACHING
#####################################################

########################### NEED TO FIX
##################################################################
##### Origin request policy for static (minimal)
###################################################################
# Explanation: Static origins need almost nothing—Chewbacca forwards minimal values for maximum cache sanity.
resource "aws_cloudfront_origin_request_policy" "orp_static" {
  name    = "${var.name_prefix}-orp-static"
  comment = "Minimal forwarding for static assets"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
}
##################################################
resource "aws_cloudfront_cache_policy" "static_cache" {
  name        = "${var.name_prefix}-static-cache"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    # Explanation: Static should not vary on cookies—Chewbacca refuses to cache 10,000 versions of a PNG.
    cookies_config { cookie_behavior = "none" }

    # Explanation: Static should not vary on query strings (unless you do versioning); students can change later.
    query_strings_config { query_string_behavior = "none" }

    # Explanation: Keep headers out of cache key to maximize hit ratio.
    headers_config { header_behavior = "none" }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
############################################################
##### Cache policy for API (safe default: caching disabled)
##############################################################
# Explanation: APIs are dangerous to cache by accident—Chewbacca disables caching until proven safe.
resource "aws_cloudfront_cache_policy" "api-cache_disabled" {
  name        = "${var.name_prefix}-api-cache-disabled"
  comment     = "Disable caching for /api/* by default"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }

    # Explanation: Forward auth-related headers to origin, but DO NOT include random headers in cache key.
    # Students: choose only required headers (Authorization is the classic case).
    headers_config { header_behavior = "none" }
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false
  }
}
############################################################
##### Origin request policy for API (forward what origin needs)
##############################################################
# Explanation: Origins need context—Chewbacca forwards what the app needs without polluting the cache key.
resource "aws_cloudfront_origin_request_policy" "orp_api" {
  name    = "${var.name_prefix}-orp-api"
  comment = "Forward necessary values for API calls"

  cookies_config { cookie_behavior = "all" }
  query_strings_config { query_string_behavior = "all" }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Accept"]
    }
  }
}

##############################################################
##### Response headers policy (optional but nice)
##############################################################
# Explanation: Make caching intent explicit—Chewbacca stamps Cache-Control so humans and CDNs agree.
resource "aws_cloudfront_response_headers_policy" "rsp_static" {
  name    = "${var.name_prefix}-rsp-static"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
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
########################### NEED TO FIX
# ========== HONORS A: Origin-Driven Caching ==========
# Custom policy that respects origin's Cache-Control header
resource "aws_cloudfront_cache_policy" "helga_cache_origin_driven01" {
  name        = "helga-cache-origin-driven"
  comment     = "Respects origin Cache-Control headers"
  min_ttl     = 0     # Can honor origin's shorter TTL
  default_ttl = 0     # Default to no caching unless origin says otherwise
  max_ttl     = 86400 # Cap at 1 day

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}