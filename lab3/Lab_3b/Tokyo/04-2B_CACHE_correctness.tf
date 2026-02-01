resource "aws_cloudfront_cache_policy" "helga_cache_staticlab3" {
  name        = "helga-cache-static-aggressive"
  comment     = "Aggressive caching for static assets"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"  # Don't include cookies in cache key
    }
    headers_config {
      header_behavior = "none"  # Don't include headers in cache key
    }
    query_strings_config {
      query_string_behavior = "none"  # Don't include query strings in cache key
    }
  }
}

resource "aws_cloudfront_cache_policy" "helga_cache_api_disabledlab3" {
  name        = "helga-cache-api-disabled"
  comment     = "No caching for API - safety first"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

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


# Instead of creating a custom policy, use AWS managed policy
# Use AWS managed policy for API (forwards all headers including Authorization)
data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}

# Keep your custom static policy - that one is fine
resource "aws_cloudfront_origin_request_policy" "helga_orp_staticlab3" {
  name    = "helga-orp-static"
  comment = "Minimal forwarding for static assets"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

/* The first attempt
resource "aws_cloudfront_origin_request_policy" "helga_orp_apilab3" {
  name    = "helga-orp-api"
  comment = "Forward what the API origin needs"

  cookies_config {
    cookie_behavior = "all"  # Forward all cookies to origin
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Authorization", "Host", "Origin", "Accept"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"  # Forward all query strings to origin
  }
}

 */

resource "aws_cloudfront_response_headers_policy" "helga_response_headerslab3" {
  name    = "helga-response-headers-static"
  comment = "Cache-Control and security headers for static"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=31536000, immutable"
      override = true
    }
  }

  security_headers_config {
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
  }
}

# ========== HONORS A: Origin-Driven Caching ==========
# Custom policy that respects origin's Cache-Control header
resource "aws_cloudfront_cache_policy" "helga_cache_origin_drivenlab3" {
  name        = "helga-cache-origin-driven"
  comment     = "Respects origin Cache-Control headers"
  min_ttl     = 0           # Can honor origin's shorter TTL
  default_ttl = 0           # Default to no caching unless origin says otherwise
  max_ttl     = 86400       # Cap at 1 day

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