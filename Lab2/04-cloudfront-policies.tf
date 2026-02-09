############################################
# CloudFront Cache & Origin Request Policies
# Lab 2: Fixed version - resolves AWS API errors
############################################

# Managed Origin Request Policy - Forwards all viewer headers/cookies/query strings
data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}

############################################
# Cache Policy: API with caching disabled
############################################
# FIXED: When caching is disabled (TTL=0), header_behavior MUST be "none"
# AWS doesn't allow header whitelisting when caching is completely disabled

resource "aws_cloudfront_cache_policy" "helga_cache_api_disabled01" {
  name        = "${var.project_name}-cache-api-disabled01"
  comment     = "No caching for dynamic API routes"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "none"  # FIXED: Must be "none" when caching disabled
    }
    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

############################################
# Cache Policy: Static content (24 hours)
############################################

resource "aws_cloudfront_cache_policy" "helga_cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "24-hour cache for static assets"
  min_ttl     = 0
  default_ttl = 86400     # 24 hours
  max_ttl     = 31536000  # 1 year

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
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

############################################
# Cache Policy: Origin-driven (respects Cache-Control)
############################################

resource "aws_cloudfront_cache_policy" "helga_cache_origin_driven01" {
  name        = "${var.project_name}-cache-origin-driven01"
  comment     = "Respect origin Cache-Control headers"
  min_ttl     = 0
  default_ttl = 0      # Origin decides
  max_ttl     = 86400

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
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

############################################
# Origin Request Policy: Static content
############################################
# FIXED: Accept-Encoding is CloudFront-managed and cannot be in whitelist
# Only Accept header is needed

resource "aws_cloudfront_origin_request_policy" "helga_orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static content"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Accept"]  # FIXED: Removed Accept-Encoding (CloudFront-managed)
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

############################################
# Response Headers Policy: Security headers
############################################

resource "aws_cloudfront_response_headers_policy" "helga_response_headers01" {
  name    = "${var.project_name}-response-headers01"
  comment = "Security headers for static content"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  custom_headers_config {
    items {
      header   = "X-Powered-By"
      value    = "Ewok-Stack"
      override = true
    }
  }
}
