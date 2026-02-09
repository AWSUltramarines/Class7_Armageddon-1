############################################
# Lab 2B-Honors - Origin Driven Caching (Managed Policies)
############################################

# AWS managed cache policy: honors origin Cache-Control headers.
# If origin sends Cache-Control → CloudFront obeys it.
# If origin sends nothing → CloudFront does NOT cache.
data "aws_cloudfront_cache_policy" "use_origin_cache_headers" {
  name = "UseOriginCacheControlHeaders"
}

# Same as above but also includes query strings in the cache key
# when the API truly varies responses by query string.
data "aws_cloudfront_cache_policy" "use_origin_cache_headers_qs" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# Managed origin request policy: forwards all viewer headers except Host.
# Keeps the cache key clean while letting the origin see what it needs.
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}
