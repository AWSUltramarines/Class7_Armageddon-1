#################################################
#1) Cache policy for static content (aggressive)
##############################################################

# Explanation: Static files are the easy win—Chewbacca caches them like hyperfuel for speed.
resource "aws_cloudfront_cache_policy" "cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400        # 1 day
  max_ttl     = 31536000     # 1 year
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
#2) Cache policy for API (safe default: caching disabled)
##############################################################



# Explanation: APIs are dangerous to cache by accident—Chewbacca disables caching until proven safe.
resource "aws_cloudfront_cache_policy" "cache_api_disabled01" {
  name        = "${var.project_name}-cache-api-disabled01"
  comment     = "Disable caching for /api/* by default"
  # default_ttl = 0 means no caching unless origin sends Cache-Control.
  # max_ttl > 0 keeps CloudFront in "origin-driven" mode (not "disabled"),
  # which allows full cache key and encoding configuration.
  default_ttl = 0
  max_ttl     = 0       # Cap at 1 day if origin opts in
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    # Cache key kept minimal — forwarding is handled by the origin request policy.
    cookies_config { cookie_behavior = "none"}   
    query_strings_config { query_string_behavior = "none" }
    headers_config {
      header_behavior = "none"
      # headers sub-block not allowed when behavior is "none" —
      # CloudFront rejects items in the cache key when caching is disabled.
      # headers {
      #   items = ["Authorization", "Host"]
      # }
    }

    # Encoding must be false when caching is disabled (all TTLs = 0) —
    # CloudFront does not compress responses it will not cache.
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false
  }
}


############################################################
#3) Origin request policy for API (forward what origin needs)
##############################################################


# Explanation: Origins need context—Chewbacca forwards what the app needs without polluting the cache key.
resource "aws_cloudfront_origin_request_policy" "orp_api01" {
  name    = "${var.project_name}-orp-api01"
  comment = "Forward necessary values for API calls"

  cookies_config { cookie_behavior = "all" }
  query_strings_config { query_string_behavior = "all" }

  headers_config {
    header_behavior = "whitelist"
    headers {
      # Authorization is forwarded automatically when caching is disabled — CloudFront
      # does not allow it in an origin request policy whitelist.
      items = ["Content-Type", "Origin", "Host"]
    }
  }
}

##################################################################
# 4) Origin request policy for static (minimal)
##############################################################


# Explanation: Static origins need almost nothing—Chewbacca forwards minimal values for maximum cache sanity.
resource "aws_cloudfront_origin_request_policy" "orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }
}

##############################################################
# 5) Response headers policy (optional but nice)
##############################################################

# Explanation: Make caching intent explicit—Chewbacca stamps Cache-Control so humans and CDNs agree.
resource "aws_cloudfront_response_headers_policy" "rsp_static01" {
  name    = "${var.project_name}-rsp-static01"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}


##############################################################
#6) Patch your CloudFront distribution behaviors
##############################################################

# These behavior blocks have been applied directly inside the CloudFront
# distribution resource in lab2_cloudfront_alb.tf.
#
# default_cache_behavior (catch-all) uses API policies:
#   cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
#   origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id
#
# ordered_cache_behavior (path_pattern = "/static/*") uses static policies:
#   cache_policy_id            = aws_cloudfront_cache_policy.cache_static01.id
#   origin_request_policy_id   = aws_cloudfront_origin_request_policy.orp_static01.id
#   response_headers_policy_id = aws_cloudfront_response_headers_policy.rsp_static01.id
#
# ordered_cache_behavior (path_pattern = "/api/*") uses API policies:
#   cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
#   origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id

